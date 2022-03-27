#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#define FPS_LOGIC_INTERVAL 1.0/20.0
#define DEFAULT_DAMAGE_START 100
#define DEFAULT_DAMAGE_DEFLECT 50
#define DEFAULT_SPEED_START 812.5
#define DEFAULT_SPEED_DEFLECT 125.0
#define DEFAULT_ORBIT_START 0.335
#define DEFAULT_ORBIT_DEFLECT 0.0140
#define DEFAULT_EVA_LIMIT 0.09
#define DEFAULT_EVA_RATE 0.147
float SPEED_START = DEFAULT_SPEED_START;
float SPEED_DEFLECT = DEFAULT_SPEED_DEFLECT;
float ORBIT_START = DEFAULT_ORBIT_START;
float ORBIT_DEFLECT = DEFAULT_ORBIT_DEFLECT;
float EVA_LIMIT = DEFAULT_EVA_LIMIT;
float EVA_RATE = DEFAULT_EVA_RATE;
float g_fRocketSpeed;
float fTurnRate;
float g_fRocketLastBeepTime;
float g_fRocketDirection[3];
int g_iSpawnPointsRedEntity;
int g_iSpawnPointsBluEntity;
int g_iRocketDeflections;
int g_iRocketSpeed;
int SelectTargetCreate;
int ObjectRocket;
int ObjectTarget;
bool g_bRocketIsValid;
bool eva_status;
Handle g_hLogicTimer;
Handle g_hTimerHud;
Handle g_hHud;
public void OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
	HookEvent("player_team", OnPlayerChangeTeam, EventHookMode_Pre);
	ServerCommand("sm_cvar tf_flamethrower_burstammo 0");
	g_hHud = CreateHudSynchronizer();

}
public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (BothTeamsPlaying() == true)
	{
		PopulateSpawnPoints();
		SelectTargetCreate = GetRandomInt(2, 3);
		g_hLogicTimer = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
	}
}
public void PopulateSpawnPoints()
{
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
	{
		char strName[32];
		GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
			g_iSpawnPointsRedEntity = iEntity;
		if ((StrContains(strName, "rocket_spawn_blue") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
			g_iSpawnPointsBluEntity = iEntity;
	}
}
public Action OnDodgeBallGameFrame(Handle hTimer)
{
	if (g_bRocketIsValid)	HomingRocketThink();
	else
		if (SelectTargetCreate == 2)	CreateRocket(g_iSpawnPointsRedEntity, 2);
		else	CreateRocket(g_iSpawnPointsBluEntity, 3);
}
public void CreateRocket(int iSpawnerEntity, int iTeam)
{
	float fPosition[3], fAngles[3], fDirection[3];
	int iTargetTeam = GetAnalogueTeam(iTeam);
	ObjectRocket = CreateEntityByName("tf_projectile_rocket");
	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
	GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity", 0);
	SetEntProp(ObjectRocket, Prop_Send, "m_bCritical", 1);
	SetEntProp(ObjectRocket, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(ObjectRocket, Prop_Send, "m_iDeflected", 1);
	TeleportEntity(ObjectRocket, fPosition, fAngles, NULL_VECTOR);
	ObjectTarget = SelectTarget(iTargetTeam);
	g_fRocketLastBeepTime = GetGameTime();
	g_fRocketSpeed = SPEED_START;
	fTurnRate = ORBIT_START;
	g_iRocketDeflections = 0;
	g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
	CopyVectors(fDirection, g_fRocketDirection);
	DispatchSpawn(ObjectRocket);
	SDKHook(ObjectRocket, SDKHook_StartTouch, OnStartTouch);
	EmitSoundToClient(ObjectTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
	g_bRocketIsValid = true;
}
public void HomingRocketThink()
{
	int iDeflectionCount = GetEntProp(ObjectRocket, Prop_Send, "m_iDeflected") - 1;
	if (!IsValidClient(ObjectTarget, true))
	{
		int iTeam = GetEntProp(ObjectRocket, Prop_Send, "m_iTeamNum", 1);
		int iTargetTeam = GetAnalogueTeam(iTeam);
		ObjectTarget = SelectTarget(iTargetTeam);
		if (!IsValidClient(ObjectTarget, true)) return;
		EmitSoundToClient(ObjectTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
	}
	else if ((iDeflectionCount > g_iRocketDeflections))
	{
		int iClient = GetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity");
		int iTeam = GetEntProp(ObjectRocket, Prop_Send, "m_iTeamNum", 1);
		int iTargetTeam = GetAnalogueTeam(iTeam);
		float fViewAngles[3], fDirection[3];
		GetClientEyeAngles(iClient, fViewAngles);
		GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
		CopyVectors(fDirection, g_fRocketDirection);
		ObjectTarget = SelectTarget(iTargetTeam);
		g_iRocketDeflections = iDeflectionCount;
		g_fRocketSpeed = SPEED_START + SPEED_DEFLECT * iDeflectionCount;
		fTurnRate = ORBIT_START + ORBIT_DEFLECT * iDeflectionCount;
		g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
		EmitSoundToClient(ObjectTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
		eva_status = true;
	}
	else
	{
		float fDirectionToTarget[3]; CalculateDirectionToClient(fDirectionToTarget);
		if (eva_status)
		{
			if (g_fRocketDirection[2] < EVA_LIMIT)
			{
				g_fRocketDirection[2] = FMin(g_fRocketDirection[2] + EVA_RATE, EVA_LIMIT);
				fDirectionToTarget[2] = g_fRocketDirection[2];
			}
			else
			{
				eva_status = false;
			}
		}
		LerpVectors(g_fRocketDirection, fDirectionToTarget, g_fRocketDirection, fTurnRate);
	}
	if ((GetGameTime() - g_fRocketLastBeepTime) >= 0.5)
	{
		EmitSoundToAll("weapons/sentry_scan.wav", ObjectRocket);
		g_fRocketLastBeepTime = GetGameTime();
	}
	ApplyRocketParameters();
}
stock void CalculateDirectionToClient(float fOut[3])
{
	float fRocketPosition[3]; GetEntPropVector(ObjectRocket, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(ObjectTarget, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}
stock void ApplyRocketParameters()
{
	float fAngles[3]; GetVectorAngles(g_fRocketDirection, fAngles);
	float fVelocity[3]; CopyVectors(g_fRocketDirection, fVelocity);
	ScaleVector(fVelocity, g_fRocketSpeed);
	SetEntPropVector(ObjectRocket, Prop_Data, "m_vecAbsVelocity", fVelocity);
	SetEntPropVector(ObjectRocket, Prop_Send, "m_angRotation", fAngles);
}
stock void LerpVectors(float fA[3], float fB[3], float fC[3], float t)
{
	if (t > 1.0) t = 1.0;
	fC[0] = fA[0] + (fB[0] - fA[0]) * t;
	fC[1] = fA[1] + (fB[1] - fA[1]) * t;
	fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}
stock Float:FMin(Float:a, Float:b)
{
	return (a < b)? a:b;
}
stock void CopyVectors(float fFrom[3], float fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}
public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return;
	int iClass = GetEntProp(iClient, Prop_Send, "m_iClass");
	if (!(iClass == 7 || iClass == 0 ))
	{
		SetEntProp(iClient, Prop_Send, "m_iDesiredPlayerClass", 7);			
		SetEntProp(iClient, Prop_Send, "m_iClass", 7);
		TF2_RespawnPlayer(iClient);
	}
}
public Action OnPlayerInventory(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return;
	for (int iSlot = 1; iSlot < 5; iSlot++)
	{
		int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if (iEntity != -1) RemoveEdict(iEntity);
	}
}
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	iButtons &= ~IN_ATTACK;
}
public Action Timer_HudSpeed(Handle hTimer)
{
	SetHudTextParams(-1.0, 2.0, 0.5, 255, 255, 255, 255);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsValidClient(iClient) && !IsFakeClient(iClient) && g_iRocketSpeed != 0)
			ShowSyncHudText(iClient, g_hHud, "Speed: %i m/h || Deflection: %i", g_iRocketSpeed, g_iRocketDeflections);
}
public Action OnRoundStart(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	g_iRocketSpeed = 0;
	if (g_hTimerHud != null)
	{
		KillTimer(g_hTimerHud);
		g_hTimerHud = null;
	}
	g_hTimerHud = CreateTimer(0.5, Timer_HudSpeed, _, TIMER_REPEAT);
}
public Action OnRoundEnd(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
	if (g_hTimerHud != null)
	{
		KillTimer(g_hTimerHud);
		g_hTimerHud = null;
	}
	DestroyRocket();
}
public void DestroyRocket()
{
	if (g_bRocketIsValid)
	{
		if (ObjectRocket && IsValidEntity(ObjectRocket)) RemoveEdict(ObjectRocket);
		g_bRocketIsValid = false;
	}
}
stock int GetAnalogueTeam(int iTeam)
{
	if (iTeam == 2) return 3;
	return 2;
}
public Action OnStartTouch(int entity, int other)
{
	SDKHook(entity, SDKHook_Touch, Destroy_Rocket_Touch);
	return Plugin_Handled;
}
public Action Destroy_Rocket_Touch(int entity, int other)
{
	SelectTargetCreate = GetRandomInt(2, 3);
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	int iTeam = GetEntProp(client, Prop_Send, "m_iTeamNum", 1);
	float vOrigin[3];	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	float vAngles[3];	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	DestroyRocket();

	Say_Destoy_Rocket(client);
	CreateExplosion(client, iTeam, vOrigin, vAngles);
	SDKUnhook(entity, SDKHook_Touch, Destroy_Rocket_Touch);
	return Plugin_Handled;
}
public CreateExplosion(int client, int iTeam, float vOrigin[3], float vAngles[3])
{
  int ent = CreateEntityByName("env_explosion");
  DispatchKeyValue(ent, "spawnflags", "824");
  SetEntProp(ent, Prop_Send, "m_iTeamNum", iTeam, 1);
  SetEntProp(ent, Prop_Data, "m_iMagnitude", DEFAULT_DAMAGE_START + DEFAULT_DAMAGE_DEFLECT * g_iRocketDeflections, 4);
  SetEntProp(ent, Prop_Data, "m_iRadiusOverride", 100, 4);
  SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client);
  DispatchSpawn(ent);
  TeleportEntity(ent, vOrigin, vAngles, NULL_VECTOR);
  AcceptEntityInput(ent, "Explode", -1, -1, 0);
}
public void Say_Destoy_Rocket(int client)
{
	char name[32], colorname[] = "\x073EFF3E";
	GetClientName(client, name, sizeof(name));
	if (client > 0)
		switch (GetClientTeam(client))
		{
			case 2: colorname = "\x07FF4040";
			case 3: colorname = "\x0799CCFF";
			default: colorname = "\x073EFF3E";
		}
	PrintToChatAll("%s%s \x01: Speed: \x0799FF99%i\x01 || Deflection: \x0799FF99%i\x01", colorname, name, g_iRocketSpeed, g_iRocketDeflections);
}
stock int SelectTarget(int iTeam)
{
	int iTarget = -1;
	float fTargetWeight = 0.0;
	float fRocketPosition[3];
	float fRocketDirection[3];
	float fWeight = 25.0;
	GetEntPropVector(ObjectRocket, Prop_Send, "m_vecOrigin", fRocketPosition);
	CopyVectors(g_fRocketDirection, fRocketDirection);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidClient(iClient, true)) continue;
		if (iTeam && GetClientTeam(iClient) != iTeam) continue;
		float fNewWeight = GetRandomFloat(0.0, 100.0);
		float fClientPosition[3]; GetClientEyePosition(iClient, fClientPosition);
		float fDirectionToClient[3]; MakeVectorFromPoints(fRocketPosition, fClientPosition, fDirectionToClient);
		fNewWeight += GetVectorDotProduct(fRocketDirection, fDirectionToClient) * fWeight;		
		if ((iTarget == -1) || fNewWeight >= fTargetWeight)
		{
			iTarget = iClient;
			fTargetWeight = fNewWeight;
		}
	}
	return iTarget;
}
stock bool BothTeamsPlaying()
{
	bool bRedFound, bBluFound;
	int iTeam;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient, true) == false) continue;
		iTeam = GetClientTeam(iClient);
		if (iTeam == 2) bRedFound = true;
		if (iTeam == 3) bBluFound = true;
	}
	return bRedFound && bBluFound;
}
stock bool IsValidClient(int iClient, bool bAlive = false)
{
	if (iClient >= 1 &&
		iClient <= MaxClients &&
		IsClientConnected(iClient) &&
		IsClientInGame(iClient) &&
		(bAlive == false || IsPlayerAlive(iClient)))
	{
		return true;
	}
	return false;
}
public void OnClientDisconnect_Post(int client)
{
	if (g_bRocketIsValid && client == GetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity"))
	{
		g_bRocketIsValid = false;
	}
}
public Action OnPlayerChangeTeam(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (g_bRocketIsValid && client == GetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity"))
	{
		g_bRocketIsValid = false;
	}
}
public void OnMapStart()
{
	g_bRocketIsValid = false;
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
}
public void OnMapEnd()
{
	g_bRocketIsValid = false;
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
}
public void RandomPhysics()
{
	float coefficient_value = GetRandomFloat(0.98, 1.2)
 	ORBIT_START = DEFAULT_ORBIT_START*coefficient_value;
	ORBIT_DEFLECT = DEFAULT_ORBIT_DEFLECT*coefficient_value;
	SPEED_START = DEFAULT_SPEED_START*coefficient_value;
	SPEED_DEFLECT = DEFAULT_SPEED_DEFLECT*coefficient_value;
}