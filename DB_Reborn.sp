#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <rank>
#include <bot>
#define DEFAULT_DAMAGE_START 50.0
#define DEFAULT_DAMAGE_DEFLECT 25.0
float DEFAULT_SPEED_START = 950.0;
float DEFAULT_SPEED_DEFLECT = 300.0;
float DAMAGE_START = DEFAULT_DAMAGE_START;
float DAMAGE_DEFLECT = DEFAULT_DAMAGE_DEFLECT;
float DEFAULT_ORBIT_START = 0.270;
float DEFAULT_ORBIT_DEFLECT = 0.0333;
float SPEED_START;
float SPEED_DEFLECT;
float ORBIT_START;
float ORBIT_DEFLECT;
float g_fRocketSpeed;
float fTurnRate;
float g_fRocketLastBeepTime;
float g_fRocketDirection[3];
int g_iSpawnPointsRedEntity;
int g_iSpawnPointsBluEntity;
int g_iRocketDeflections;
int g_iRocketSpeed;
int SelectTargetCreate;
int rocket = INVALID_ENT_REFERENCE;
int ObjectTarget;
int Speed_record[MAXPLAYERS+1];
int Deflect_record[MAXPLAYERS+1];
bool bot_status = false;
bool StopPause;
char obj_destry[32];
Handle g_hLogicTimer;
Handle g_hHud;
int ClientSay[MAXPLAYERS+1] = 0;
float TickRate = 100.0;
bool deflectStatus = false;
int targetlock = 0;
int m_hLauncher = -1;
float orbit_limit = 0.0;
float orbit_coef = 0.0;
public void OnPluginStart()
{
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
	RegAdminCmd("sm_bot_mod", ModeBotSettings, ADMFLAG_GENERIC);
	RegAdminCmd("sm_speed_start", Command_speed_start, ADMFLAG_CONVARS, "Set parameter");
	RegAdminCmd("sm_speed_deflect", Command_speed_deflect, ADMFLAG_CONVARS, "Set parameter");
	RegAdminCmd("sm_orbit_start", Command_orbit_start, ADMFLAG_CONVARS, "Set parameter");
	RegAdminCmd("sm_orbit_deflect", Command_orbit_deflect, ADMFLAG_CONVARS, "Set parameter");
	RegAdminCmd("sm_get", Command_get, ADMFLAG_CONVARS, "Set parameter");
	g_hHud = CreateHudSynchronizer();
	LoadRate(0);
	CreateTimer(1200.0, Clear_Client_Say, _, TIMER_REPEAT);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			OnClientPutInServer(i);
		}
	}
}
public Action:Command_speed_start(client, args)
{
	char arg1[16] = "";	GetCmdArg(1, arg1, sizeof(arg1));
	float speed = StringToFloat(arg1);
	orbit_coef = GetTurnCoef(speed, DEFAULT_ORBIT_START * 10);
	DEFAULT_SPEED_START = speed;
	DEFAULT_ORBIT_START = orbit_coef*DEFAULT_SPEED_START;
	LoadRate(1);
	PrintToChat(client, arg1);
	return Plugin_Handled;
}
public Action:Command_speed_deflect(client, args)
{
	char arg1[16] = "";	GetCmdArg(1, arg1, sizeof(arg1));
	float speed = StringToFloat(arg1);
	orbit_coef = GetTurnCoef(speed, DEFAULT_ORBIT_DEFLECT * 10);
	DEFAULT_SPEED_DEFLECT = speed;
	DEFAULT_ORBIT_DEFLECT = orbit_coef*DEFAULT_SPEED_DEFLECT;
	LoadRate(2);
	PrintToChat(client, arg1);
	return Plugin_Handled;
}
public Action:Command_orbit_start(client, args)
{
	char arg1[16] = "";	GetCmdArg(1, arg1, sizeof(arg1));
	float orbit = StringToFloat(arg1);
	DEFAULT_ORBIT_START = orbit;
	LoadRate(1);
	PrintToChat(client, arg1);
	return Plugin_Handled;
}
public Action:Command_orbit_deflect(client, args)
{
	char arg1[16] = "";	GetCmdArg(1, arg1, sizeof(arg1));
	float orbit = StringToFloat(arg1);
	DEFAULT_ORBIT_DEFLECT = orbit;
	LoadRate(2);
	PrintToChat(client, arg1);
	return Plugin_Handled;
}
public Action:Command_get(client, args)
{
	PrintToChatAll("speed_start: %f", SPEED_START);
	PrintToChatAll("speed_deflect: %f", SPEED_DEFLECT);
	PrintToChatAll("orbit_start: %f", DEFAULT_ORBIT_START);
	PrintToChatAll("orbit_deflect: %f", ORBIT_DEFLECT);
	return Plugin_Handled;
}
public float GetTurnCoef(float speed, float turnRate)
{
	return turnRate/speed;
}
public void OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnClientTakeDamage);
}
public Action OnClientTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if (IsValidClientFast(weapon) && m_hLauncher != -1)
	{
		weapon = m_hLauncher;
	}
	if (GetPlayerTeam())
	{
		damage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Changed;
}
stock bool GetPlayerTeam()
{
	bool red = false, blue = false;
	int count = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidClientFast(i))
		{
			if (GetClientTeam(i) == 3)
			{
				blue = true;
				count++;
			}
			if (GetClientTeam(i) == 2)
			{
				red = true;
				count++;
			}
		}
	}
	return (blue && red && count == 2) ? true : false;
}
stock bool IsValidClientFast(int client)
{
	if(client <= 0 || client > MaxClients || !IsClientConnected(client) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}
public Action ModeBotSettings(int client, args) 
{
	char arg1[16] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	int parameter_value = StringToInt(arg1);	
	if (parameter_value == 0)
	{
		DAMAGE_START = DEFAULT_DAMAGE_START;
		DAMAGE_DEFLECT = DEFAULT_DAMAGE_DEFLECT;
	}
	else
	{
		DAMAGE_START = 20.0;
		DAMAGE_DEFLECT = 0.0;
	}
	return Plugin_Handled;
}
stock void LoadRate(int updateType)
{
	TickRate = (1.0 / GetTickInterval()) / 10.0;
	if (updateType == 0)
	{
		DEFAULT_ORBIT_START = DEFAULT_ORBIT_START/TickRate;
		DEFAULT_ORBIT_DEFLECT = DEFAULT_ORBIT_DEFLECT/TickRate;
	}
	if (updateType == 1)
	{
		DEFAULT_ORBIT_START = DEFAULT_ORBIT_START/TickRate;
	}
	if (updateType == 2)
	{
		DEFAULT_ORBIT_DEFLECT = DEFAULT_ORBIT_DEFLECT/TickRate;
	}
}
public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (BothTeamsPlaying() == true)
	{
		PopulateSpawnPoints();
		SelectTargetCreate = GetRandomInt(2, 3);
		g_hLogicTimer = CreateTimer(0.1, OnDodgeBallGameFrame, _, TIMER_REPEAT);
		bot_status = GetBotStatus();
		if (!bot_status) 
		{
			Get_Rank_Info();
		}
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
		{
			g_iSpawnPointsRedEntity = iEntity;
		}
		if ((StrContains(strName, "rocket_spawn_blue") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
		{
			g_iSpawnPointsBluEntity = iEntity;
		}
	}
}
public void OnEntityCreated(int entity, const char[] classname)
{
	if (StrEqual(classname, "tf_projectile_rocket", false))
	{
		rocket = entity;
		SDKHook(rocket, SDKHook_StartTouch, OnStartTouch);
	}
}
public void OnEntityDestroyed(int entity)
{
	if (rocket == entity)
	{	
		rocket = INVALID_ENT_REFERENCE;
	}
}
public void OnGameFrame()
{
	if (rocket != INVALID_ENT_REFERENCE)
	{
		int iDeflectionCount = GetEntProp(rocket, Prop_Send, "m_iDeflected") - 1;
		if (iDeflectionCount > g_iRocketDeflections)
		{
			//float speedreal[3];
			//GetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", speedreal);
			//PrintToChatAll("real speed: %f", GetVectorLength(speedreal));
			StopPause = false; deflectStatus = true;
			g_iRocketDeflections = iDeflectionCount;
			g_fRocketSpeed = SPEED_START + SPEED_DEFLECT * iDeflectionCount;
			fTurnRate = ORBIT_START + ORBIT_DEFLECT * iDeflectionCount; 
			if (fTurnRate > 1.0) 
			{
				fTurnRate = 1.0;
			}
			SetEntDataFloat(rocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, DAMAGE_START + DAMAGE_DEFLECT * iDeflectionCount, true);
			m_hLauncher = GetEntPropEnt(rocket, Prop_Send, "m_hLauncher");
			SetEntPropEnt(rocket, Prop_Send, "m_hOriginalLauncher", GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity"));
			SetEntPropEnt(rocket, Prop_Send, "m_hLauncher", GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity"));
		}
		if (!IsValidClient(ObjectTarget, true))	
		{
			ObjectTarget = SelectTarget(0);
		}
		else
		{
			float fDirectionToTarget[3]; 
			CalculateDirectionToClient(fDirectionToTarget);
			LerpVectors(fDirectionToTarget, g_fRocketDirection);
			if (StopPause)
			{
				ApplyRocketParameters();
			}
		}
	}
}
stock void CalculateDirectionToClient(float fOut[3])
{
	float fRocketPosition[3];
	GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", fRocketPosition);
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
	//NormalizeVector(fVelocity, fVelocity);
	//ScaleVector(fVelocity, g_fRocketSpeed);
	SetEntPropVector(rocket, Prop_Send, "m_angRotation", fAngles);
	SetEntPropVector(rocket, Prop_Data, "m_vecAbsVelocity", fVelocity);
}
stock void CopyVectors(float fFrom[3], float fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}
public Action OnDodgeBallGameFrame(Handle hTimer)
{
	if (rocket != INVALID_ENT_REFERENCE)
	{
		if (deflectStatus)
		{
			deflectStatus = false;
			int iClient = GetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity");
			float fViewAngles[3], fDirection[3];
			if (iClient != 0)
			{
				GetClientEyeAngles(iClient, fViewAngles);
				GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
				CopyVectors(fDirection, g_fRocketDirection);
				ObjectTarget = SelectTarget(iClient);
				if (bot_status)
				{
					targetlock = iClient;
				}
				g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
				if (!bot_status) 
				{
					Set_Record_Speed(iClient, g_iRocketSpeed, g_iRocketDeflections);
				}
				orbit_limit = 0.0;
			}
		}
		if ((GetGameTime() - g_fRocketLastBeepTime) >= 0.5)
		{
			EmitSoundToAll("weapons/sentry_scan.wav", rocket);
			g_fRocketLastBeepTime = GetGameTime();
			HudUpdate();
		}
		if (!StopPause)	
		{
			ApplyRocketParameters();
		}
		orbit_limit += 0.1;
		if (orbit_limit > 10.0)
		{
			PrintToChat(ObjectTarget,"\x073EFF3E[Oracle]\x01 : Anti turn spam", ObjectTarget);
			g_fRocketSpeed = 15000.0;
		}
		if (orbit_limit > 12.5)
		{
			fTurnRate = 1.0;
		}
		StopPause = true;
	}
	else
	{
		if (SelectTargetCreate == 2)
		{
			CreateRocket(g_iSpawnPointsRedEntity, 2);
		}
		else	
		{
			CreateRocket(g_iSpawnPointsBluEntity, 3);
		}
	}
}
public void CreateRocket(int iSpawnerEntity, int iTeam)
{
	float fPosition[3], fAngles[3], fDirection[3];
	rocket = CreateEntityByName("tf_projectile_rocket");
	SetRate();
	orbit_limit = 0.0;
	if (rocket != INVALID_ENT_REFERENCE)
	{
		GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
		GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
		GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(rocket, Prop_Send, "m_hOwnerEntity", 0);
		SetEntProp(rocket, Prop_Send, "m_bCritical", 1);
		SetEntProp(rocket, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(rocket, Prop_Send, "m_iDeflected", 1);
		SetEntDataFloat(rocket, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, DAMAGE_START, true);
		TeleportEntity(rocket, fPosition, fAngles, NULL_VECTOR);
		ObjectTarget = SelectTarget(0);
		g_fRocketLastBeepTime = GetGameTime();
		g_fRocketSpeed = SPEED_START;
		fTurnRate = ORBIT_START;
		g_iRocketDeflections = 0;
		g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
		CopyVectors(fDirection, g_fRocketDirection);
		if (IsValidEntity(rocket))
		{
			DispatchSpawn(rocket);
		}
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
public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) 
	{
		return;
	}
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
	if (!IsValidClient(iClient)) 
	{
		return;
	}
	for (int iSlot = 1; iSlot < 5; iSlot++)
	{
		int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if (iEntity != -1) 
		{
			RemoveEdict(iEntity);
		}
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
	{
		if (IsValidClient(iClient) && !IsFakeClient(iClient))
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
	DestroyRocket();
}
public void DestroyRocket()
{
	if (IsValidEntity(rocket)) 
	{
		RemoveEdict(rocket);
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
		Destroy_Rocket_Touch(entity);
		return Plugin_Handled;
	}
	if (GetEdictClassname(other, obj_destry, sizeof(obj_destry)) && strncmp(obj_destry, "obj_", 4, false) == 0)
	{
		Destroy_Rocket_Touch(entity);
		return Plugin_Handled;
	}
	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public void Destroy_Rocket_Touch(int entity)
{
	SelectTargetCreate = GetRandomInt(2, 3);
	int client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	//float speedreal[3];
	//GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", speedreal);
	//PrintToChatAll("real speed: %f", GetVectorLength(speedreal));
	Say_Destoy_Rocket(client);
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
stock int SelectTarget(int client)
{
	int iTeam = GetEntProp(rocket, Prop_Send, "m_iTeamNum", 1);
	int iTargetTeam = GetAnalogueTeam(iTeam);
	float fTargetWeight = 0.0;
	float fRocketPosition[3];
	int iTarget = -1;
	GetEntPropVector(rocket, Prop_Send, "m_vecOrigin", fRocketPosition);
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidClient(iClient, true)) 
		{
			continue;
		}
		if (iTargetTeam && GetClientTeam(iClient) != iTargetTeam) 
		{
			continue;
		}
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
	if (bot_status)
	{
		if (IsValidClient(targetlock, true) && GetClientTeam(targetlock) != iTeam)
		{
			iTarget = targetlock;
		}
	}
	if (IsValidClient(iTarget, true)) 
	{
		EmitSoundToClient(iTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
	}
	else	
	{
		DestroyRocket();
	}
	if (client != 0)
	{
		if(ObjectTarget != client && !IsFakeClient(client))
		{
			if (IsValidClient(client, true))
			{
				Say_Steal_Rocket(client);
			}
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
		if (IsValidClient(iClient, true) == false) 
		{
			continue;
		}
		iTeam = GetClientTeam(iClient);
		if (iTeam == 2) 
		{
			bRedFound = true;
		}
		if (iTeam == 3) 
		{
			bBluFound = true;
		}
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
	if (Speed_record[client] < Curr_Speed)	
	{
		SetSpeed(client, Curr_Speed);
	}
	if (Deflect_record[client] < Curr_Deflect)	
	{
		SetDeflect(client, Curr_Deflect);
	}
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
	ClientSay[client] = 0;
}
public void OnMapStart()
{
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
}
public void OnMapEnd()
{
	if (g_hLogicTimer != null)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = null;
	}
}
Say_Steal_Rocket(iClient)
{
	ClientSay[iClient]++;
	switch(ClientSay[iClient])
	{	
		case 3, 4, 5:
		{
			ForcePlayerSuicide(iClient);
			PrintToChat(iClient,"\x073EFF3E[Oracle]\x01 \x0799FF99%N\x01 : Don't steal the rocket!", iClient);
		}
		case 6,7,8,9:
		{
			ForcePlayerSuicide(iClient);
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