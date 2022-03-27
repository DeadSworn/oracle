#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rank>
#include <bot>
#define DEFAULT_DAMAGE_START 100
#define DEFAULT_DAMAGE_DEFLECT 50
#define DEFAULT_SPEED_START 950.0
#define DEFAULT_SPEED_DEFLECT 300.0
#define DEFAULT_EVA_LIMIT 0.1
#define DEFAULT_EVA_RATE 0.1235
float DEFAULT_ORBIT_START = 0.245;
float DEFAULT_ORBIT_DEFLECT = 0.03;
float SPEED_START = DEFAULT_SPEED_START;
float SPEED_DEFLECT = DEFAULT_SPEED_DEFLECT;
float ORBIT_START;
float ORBIT_DEFLECT;
float EVA_LIMIT;
float EVA_RATE;
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
int Speed_record[MAXPLAYERS+1];
int Deflect_record[MAXPLAYERS+1];
bool g_bRocketIsValid;
bool bot_status;
bool StopPause;
char obj_destry[32];
Handle g_hLogicTimer;
Handle g_hUpdateTimer;
Handle g_hHud;
int ClientSay[MAXPLAYERS+1] = 0;
float coefRoundIncDefault = 0.1;
float coefRoundInc;
bool modeGame = false; // 0 - standart, 1 - time dependence
float timeR = 0.0;
float TickRate = 100.0;
float TimeCoef = 1.5;
bool evaStatus = false;
bool evaStatusDeflect = false;
public void OnPluginStart()
{
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
	HookEvent("player_team", OnPlayerChangeTeam, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("object_deflected", OnDeflect, EventHookMode_PostNoCopy);
	ServerCommand("sm_cvar tf_flamethrower_burstammo 0");
	RegAdminCmd("sm_d_inc", SetIncCoef, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tr", TimeRateFunc, ADMFLAG_GENERIC);
	RegAdminCmd("sm_mode", SwitchMode, ADMFLAG_GENERIC);
	RegAdminCmd("sm_eva", EvaEnable, ADMFLAG_GENERIC);
	g_hHud = CreateHudSynchronizer();
	LoadRate();
	CreateTimer(1200.0, Clear_Client_Say, _, TIMER_REPEAT);
}
public Action TimeRateFunc(int client, args) 
{
	char arg1[16] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	float parameter_value = StringToFloat(arg1);
	TimeCoef = parameter_value;
	return Plugin_Handled;
}
public Action SwitchMode(int client, args) 
{
	modeGame = !modeGame;
	PrintToChatAll("Mode switch: %i", modeGame);
	return Plugin_Handled;
}
public Action EvaEnable(int client, args) 
{
	evaStatus = !evaStatus;
	PrintToChatAll("Eva status: %i", evaStatus);
	return Plugin_Handled;
}
public Action SetIncCoef(int client, args) 
{
	char arg1[16] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	float parameter_value = StringToFloat(arg1);
	coefRoundIncDefault = parameter_value;
	coefRoundInc = 1.0 + coefRoundIncDefault;
	return Plugin_Handled;
}
stock void LoadRate()
{
	TickRate = (1.0/GetTickInterval())/10.0;
	DEFAULT_ORBIT_START = DEFAULT_ORBIT_START/TickRate;
	DEFAULT_ORBIT_DEFLECT = DEFAULT_ORBIT_DEFLECT/TickRate;
	EVA_LIMIT = DEFAULT_EVA_LIMIT/TickRate;
	EVA_RATE = DEFAULT_EVA_RATE/TickRate;
}
public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (BothTeamsPlaying() == true)
	{
		PopulateSpawnPoints();
		SelectTargetCreate = GetRandomInt(2, 3);
		g_hLogicTimer = CreateTimer(0.1, OnDodgeBallGameFrame, _, TIMER_REPEAT);
		g_hUpdateTimer = CreateTimer(0.1, UpdeterTimer, _, TIMER_REPEAT);
		coefRoundInc = 1.0 + coefRoundIncDefault;
		bot_status = GetBotStatus();
		timeR = 0.0;
	}
}
public Action UpdeterTimer(Handle hTimer)
{
	if (g_bRocketIsValid && modeGame == true)
	{
			g_fRocketSpeed += (SPEED_DEFLECT/TimeCoef)/TickRate;
			fTurnRate += (ORBIT_DEFLECT/TimeCoef)/TickRate;
			if (fTurnRate > 1.0) fTurnRate = 1.0;
			timeR += 0.1;
			g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
			HudUpdate();
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
public void OnGameFrame()
{
	if (g_bRocketIsValid)
	{
		float fDirectionToTarget[3]; CalculateDirectionToClient(fDirectionToTarget);
		if (evaStatus && evaStatusDeflect)
		{
			if (g_fRocketDirection[2] < EVA_LIMIT)
			{
				g_fRocketDirection[2] = (g_fRocketDirection[2] + EVA_RATE < EVA_LIMIT) ? g_fRocketDirection[2] + EVA_RATE:EVA_LIMIT;
				fDirectionToTarget[2] = g_fRocketDirection[2];
			}
			else
			{
				evaStatusDeflect = false;
			}
		}
		LerpVectors(fDirectionToTarget, g_fRocketDirection);
		if (StopPause)	ApplyRocketParameters();
	}
}
stock void CalculateDirectionToClient(float fOut[3])
{
	float fRocketPosition[3]; GetEntPropVector(ObjectRocket, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(ObjectTarget, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}
stock void LerpVectors(float fB[3], float fC[3])
{
	fC[0] = fC[0] + (fB[0] - fC[0]) * fTurnRate;
	fC[1] = fC[1] + (fB[1] - fC[1]) * fTurnRate;
	fC[2] = fC[2] + (fB[2] - fC[2]) * fTurnRate;
}
stock void ApplyRocketParameters()
{
	float fAngles[3]; GetVectorAngles(g_fRocketDirection, fAngles);
	float fVelocity[3]; CopyVectors(g_fRocketDirection, fVelocity);
	ScaleVector(fVelocity, g_fRocketSpeed);
	SetEntPropVector(ObjectRocket, Prop_Data, "m_vecAbsVelocity", fVelocity);
	SetEntPropVector(ObjectRocket, Prop_Send, "m_angRotation", fAngles);
}
stock void CopyVectors(float fFrom[3], float fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}
public Action OnDodgeBallGameFrame(Handle hTimer)
{
	if (g_bRocketIsValid)
	{
		int iDeflectionCount = GetEntProp(ObjectRocket, Prop_Send, "m_iDeflected") - 1;
		if (iDeflectionCount > g_iRocketDeflections)
		{
			StopPause = false;
			int iClient = GetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity");
			if(ObjectTarget != iClient && !bot_status)
			{
				Say_Steal_Rocket(iClient);
			}
			float fViewAngles[3], fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection);
			ObjectTarget = SelectTarget();
			g_iRocketDeflections = iDeflectionCount;
			if(modeGame == false)
			{
				g_fRocketSpeed = (SPEED_START * coefRoundInc) + SPEED_DEFLECT * iDeflectionCount;
				fTurnRate = (ORBIT_START * coefRoundInc) + ORBIT_DEFLECT * iDeflectionCount; 
			}
			if (fTurnRate > 1.0) fTurnRate = 1.0;
			g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
			if (!bot_status) Set_Record_Speed(iClient, g_iRocketSpeed, iDeflectionCount);
			evaStatusDeflect = true;
		}
		if (!IsValidClient(ObjectTarget, true))	ObjectTarget = SelectTarget();
		if ((GetGameTime() - g_fRocketLastBeepTime) >= 0.5)
		{
			EmitSoundToAll("weapons/sentry_scan.wav", ObjectRocket);
			g_fRocketLastBeepTime = GetGameTime();
		}
		if (!StopPause)	ApplyRocketParameters();
		StopPause = true;
		HudUpdate();
	}
	else
	{
		if (SelectTargetCreate == 2)	CreateRocket(g_iSpawnPointsRedEntity, 2);
		else	CreateRocket(g_iSpawnPointsBluEntity, 3);
	}
}
public void CreateRocket(int iSpawnerEntity, int iTeam)
{
	SetRate();
	float fPosition[3], fAngles[3], fDirection[3];
	ObjectRocket = CreateEntityByName("tf_projectile_rocket");
	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
	GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
	GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
	SetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity", 0);
	SetEntProp(ObjectRocket, Prop_Send, "m_bCritical", 1);
	SetEntProp(ObjectRocket, Prop_Send, "m_iTeamNum", iTeam, 1);
	SetEntProp(ObjectRocket, Prop_Send, "m_iDeflected", 1);
	TeleportEntity(ObjectRocket, fPosition, fAngles, NULL_VECTOR);
	ObjectTarget = SelectTarget();
	g_fRocketLastBeepTime = GetGameTime();
	g_fRocketSpeed = SPEED_START*coefRoundInc;
	fTurnRate = ORBIT_START;
	g_iRocketDeflections = 0;
	g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
	CopyVectors(fDirection, g_fRocketDirection);
	DispatchSpawn(ObjectRocket);
	SDKHook(ObjectRocket, SDKHook_StartTouch, OnStartTouch);
	g_bRocketIsValid = true;
	if (!bot_status) Get_Rank_Info();
	timeR = 0.0;
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
public void HudUpdate()
{
	SetHudTextParams(-1.0, 2.0, 0.5, 255, 255, 255, 255);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
		if (IsValidClient(iClient) && !IsFakeClient(iClient))
		{
			if (modeGame)
			{
				ShowSyncHudText(iClient, g_hHud, "Speed: %i m/h || Time: %.2f", g_iRocketSpeed, timeR);
			}
			else
			{
				ShowSyncHudText(iClient, g_hHud, "Speed: %i m/h || Deflection: %i", g_iRocketSpeed, g_iRocketDeflections);
			}
		}
}
public Action OnRoundEnd(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
	if (g_hUpdateTimer != null)
	{
		KillTimer(g_hUpdateTimer);
		g_hUpdateTimer = null;
	}
	DestroyRocket();
}
public void DestroyRocket()
{
	if (g_bRocketIsValid)
	{
		g_bRocketIsValid = false;
		coefRoundInc += coefRoundIncDefault;
		if (ObjectRocket && IsValidEntity(ObjectRocket)) 
		{
			RemoveEdict(ObjectRocket);
		}
	}
}
stock int GetAnalogueTeam(int iTeam)
{
	if (iTeam == 2) return 3;
	return 2;
}
public Action OnStartTouch(int entity, int other)
{
	if (other >= 1 && other <= MaxClients)
	{
		SDKHook(entity, SDKHook_Touch, Destroy_Rocket_Touch);
		return Plugin_Handled;
	}
	if (GetEdictClassname(other, obj_destry, sizeof(obj_destry)) && strncmp(obj_destry, "obj_", 4, false) == 0)
	{
		SDKHook(entity, SDKHook_Touch, Destroy_Rocket_Touch);
		return Plugin_Handled;
	}
	SDKHook(entity, SDKHook_Touch, OnTouch);
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
public Action OnTouch(int entity, int other)
{
	StopPause = false;
	float vOrigin[3], vAngles[3], vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	CloseHandle(trace);
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public bool TEF_ExcludeEntity(int entity, int contentsMask, any data)
{
	return (entity != data);
}
stock int SelectTarget()
{
	int iTeam = GetEntProp(ObjectRocket, Prop_Send, "m_iTeamNum", 1);
	int iTargetTeam = GetAnalogueTeam(iTeam);
	float fTargetWeight = 0.0;
	float fRocketPosition[3];
	int iTarget = -1;
	GetEntPropVector(ObjectRocket, Prop_Send, "m_vecOrigin", fRocketPosition);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidClient(iClient, true)) continue;
		if (iTargetTeam && GetClientTeam(iClient) != iTargetTeam) continue;
		float fNewWeight = GetRandomFloat(0.0, 100.0);
		float fClientPosition[3]; GetClientEyePosition(iClient, fClientPosition);
		float fDirectionToClient[3]; MakeVectorFromPoints(fRocketPosition, fClientPosition, fDirectionToClient);
		fNewWeight += GetVectorDotProduct(g_fRocketDirection, fDirectionToClient) * 25.0;		
		if ((iTarget == -1) || fNewWeight >= fTargetWeight)
		{
			iTarget = iClient;
			fTargetWeight = fNewWeight;
		}
	}
	if (IsValidClient(iTarget, true)) EmitSoundToClient(iTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
	else	DestroyRocket();
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
public void Get_Rank_Info()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		Speed_record[client] = GetSpeed(client);
		Deflect_record[client] = GetDeflect(client);
	}
}
public void Set_Record_Speed(int client, int Curr_Speed, int Curr_Deflect)
{
	if (Speed_record[client] < Curr_Speed)	SetSpeed(client, Curr_Speed);
	if (Deflect_record[client] < Curr_Deflect)	SetDeflect(client, Curr_Deflect);
	SetSumDeflect(client);
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
	if (g_bRocketIsValid && ObjectTarget == client) ObjectTarget = SelectTarget();
	ClientSay[client] = 0;
}
public Action OnPlayerChangeTeam(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (g_bRocketIsValid && client == GetEntPropEnt(ObjectRocket, Prop_Send, "m_hOwnerEntity"))
	{
		g_bRocketIsValid = false;
	}
	if (g_bRocketIsValid && ObjectTarget == client) ObjectTarget = SelectTarget();
}
public Action OnPlayerDeath(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (g_bRocketIsValid)
	{
		int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if (ObjectTarget == client) ObjectTarget = SelectTarget();
	}
}
public Action OnDeflect(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	StopPause = false;
}
public void OnMapStart()
{
	g_bRocketIsValid = false;
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
	if (g_hUpdateTimer != null)
	{
		KillTimer(g_hUpdateTimer);
		g_hUpdateTimer = null;
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
	if (g_hUpdateTimer != null)
	{
		KillTimer(g_hUpdateTimer);
		g_hUpdateTimer = null;
	}
}
stock void SetRate()
{
	float coefficient_value = GetRandomFloat(0.98, 1.02);
 	ORBIT_START = (DEFAULT_ORBIT_START*coefficient_value);
	ORBIT_DEFLECT = (DEFAULT_ORBIT_DEFLECT*coefficient_value);
	SPEED_START = DEFAULT_SPEED_START*coefficient_value;
	SPEED_DEFLECT = DEFAULT_SPEED_DEFLECT*coefficient_value;
}
Say_Steal_Rocket(iClient)
{
	ClientSay[iClient]++;
	switch(ClientSay[iClient])
	{	
		case 6,7,8,9:
		{
			PrintToChat(iClient,"\x073EFF3E[Oracle]\x01 \x0799FF99%N\x01 : If you steal %i rockets that you will kick.", iClient, 10 - ClientSay[iClient]);
		}
		case 10:
		{
			KickClient(iClient, "You kicked for stealing.");
			ClientSay[iClient] = 0;
		}
		default:
		{
			PrintToChat(iClient,"\x073EFF3E[Oracle]\x01 \x0799FF99%N\x01 : Don't steal the rocket!", iClient);
		}
	}
}
public Action Clear_Client_Say(Handle hTimer) {
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i) && !IsFakeClient(i))
		{
			ClientSay[i] = 0;
		}
	}
}