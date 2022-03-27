#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>
#include <tf2items>
#include <rank>
#include <bot>
#define FPS_LOGIC_INTERVAL 1.0/20.0
#define DEFAULT_DAMAGE_START 50.0
#define DEFAULT_DAMAGE_DEFLECT 200.0
#define DEFAULT_SPEED_START 1047.0
#define DEFAULT_SPEED_DEFLECT 299.0
#define DEFAULT_ORBIT_START 0.259
#define DEFAULT_ORBIT_DEFLECT 0.0282
new Float:DAMAGE_START = DEFAULT_DAMAGE_START;
new Float:DAMAGE_DEFLECT = DEFAULT_DAMAGE_DEFLECT;
new Float:SPEED_START = DEFAULT_SPEED_START;
new Float:SPEED_DEFLECT = DEFAULT_SPEED_DEFLECT;
new Float:ORBIT_START = DEFAULT_ORBIT_START;
new Float:ORBIT_DEFLECT = DEFAULT_ORBIT_DEFLECT;
new g_iSpawnPointsRedEntity;
new g_iSpawnPointsBluEntity;
new g_iLastDeadTeam;
new g_iRocketCount;
new Float:g_fNextSpawnTime;
new g_iRocketEntity;
new g_iRocketTarget;
new g_iRocketDeflections;
new Float:g_fRocketSpeed;
new Float:g_fRocketLastBeepTime;
new Float:g_fRocketDirection[3];
new bool:g_bRocketIsValid;
new Handle:g_hLogicTimer;
new Handle:g_hTimerHud;
new Handle:g_hHud;
new g_iRocketSpeed;
new Speed_record[MAXPLAYERS+1];
new Deflect_record[MAXPLAYERS+1];
new String:obj_destry[32];
new bool:bot_status;

public OnPluginStart()
{
	HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
	HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	ServerCommand("sm_cvar tf_flamethrower_burstammo 0");
	RegAdminCmd("sm_change", ChangeParameter, ADMFLAG_CONVARS, "Set parameter");
	RegAdminCmd("sm_get_rate", Get_rate, ADMFLAG_CONVARS);
	RegAdminCmd("sm_generate", GenerateRate, ADMFLAG_CONVARS);
	g_hHud = CreateHudSynchronizer();
}
public Action:OnSetupFinished(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if (BothTeamsPlaying() == true)
	{
		PopulateSpawnPoints();
		if (g_iLastDeadTeam == 0) g_iLastDeadTeam = GetRandomInt(2, 3);
		g_hLogicTimer = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
		g_fNextSpawnTime = GetGameTime();
		bot_status = GetBotStatus();
	}
}
PopulateSpawnPoints()
{
	new iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
	{
		decl String:strName[32];
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
public Action:OnDodgeBallGameFrame(Handle:hTimer)
{
	if (BothTeamsPlaying() == false) return;
	if (GetGameTime() >= g_fNextSpawnTime)
	{
		if (g_iLastDeadTeam == 2)
		{
			if (g_iRocketCount < 1)
			{
				CreateRocket(g_iSpawnPointsRedEntity, 2);
			}
		}
		else
		{
			if (g_iRocketCount < 1)
			{
				CreateRocket(g_iSpawnPointsBluEntity, 3);
			}
		}
	}
	if (g_bRocketIsValid)
	{
		HomingRocketThink();
	}
}
public CreateRocket(iSpawnerEntity, iTeam)
{
	new iEntity = CreateEntityByName("tf_projectile_rocket");
	if (iEntity && IsValidEntity(iEntity))
	{
		new Float:fPosition[3], Float:fAngles[3], Float:fDirection[3];
		GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
		GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
		GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
		SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
		SetEntProp(iEntity, Prop_Send, "m_bCritical", 1);
		SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
		SetEntProp(iEntity, Prop_Send, "m_iDeflected", 1);
		TeleportEntity(iEntity, fPosition, fAngles, Float:{0.0, 0.0, 0.0});
		new iTargetTeam = GetAnalogueTeam(iTeam);
		new iTarget = SelectTarget(iTargetTeam);
		g_bRocketIsValid = true;
		g_iRocketEntity = EntIndexToEntRef(iEntity);
		g_iRocketTarget = EntIndexToEntRef(iTarget);
		g_iRocketDeflections = 0;
		g_fRocketLastBeepTime = GetGameTime();
		g_fRocketSpeed = SPEED_START;
		g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
		CopyVectors(fDirection, g_fRocketDirection);
		SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, DAMAGE_START, true);
		DispatchSpawn(iEntity);
		SDKHook(iEntity, SDKHook_StartTouch, OnStartTouch);
		g_iRocketCount++;
		g_fNextSpawnTime = GetGameTime() + 2.0;
		EmitSoundToClient(iTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
		if (!bot_status) Get_Rank_Info();
	}
}
HomingRocketThink()
{
	new iEntity = EntRefToEntIndex(g_iRocketEntity);
	new iTarget = EntRefToEntIndex(g_iRocketTarget);
	new iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
	new iTargetTeam = GetAnalogueTeam(iTeam);
	new iDeflectionCount = GetEntProp(iEntity, Prop_Send, "m_iDeflected") - 1;
	if (!IsValidClient(iTarget, true))
	{
		iTarget = SelectTarget(iTargetTeam);
		if (!IsValidClient(iTarget, true)) return;
		g_iRocketTarget = EntIndexToEntRef(iTarget);
		EmitSoundToClient(iTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
	}
	else if ((iDeflectionCount > g_iRocketDeflections))
	{
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(iClient))
		{
			decl Float:fViewAngles[3], Float:fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection);
		}
		iTarget = SelectTarget(iTargetTeam);
		g_iRocketTarget = EntIndexToEntRef(iTarget);
		g_iRocketDeflections = iDeflectionCount;
		g_fRocketSpeed = SPEED_START + SPEED_DEFLECT * iDeflectionCount;
		g_iRocketSpeed = RoundToNearest(g_fRocketSpeed);
		SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, DAMAGE_START + DAMAGE_DEFLECT * iDeflectionCount, true);
		EmitSoundToClient(iTarget, "weapons/sentry_spot.wav", _, _, _, _, 0.5);
		if (!bot_status) Set_Record_Speed(iClient, g_iRocketSpeed, iDeflectionCount);
	}
	else
	{
		new Float:fTurnRate = ORBIT_START + ORBIT_DEFLECT * iDeflectionCount;
		decl Float:fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);
		LerpVectors(g_fRocketDirection, fDirectionToTarget, g_fRocketDirection, fTurnRate);
	}
	if ((GetGameTime() - g_fRocketLastBeepTime) >= 0.5)
	{
		EmitSoundToAll("weapons/sentry_scan.wav", iEntity);
		g_fRocketLastBeepTime = GetGameTime();
	}
	ApplyRocketParameters();
}
CalculateDirectionToClient(iEntity, iClient, Float:fOut[3])
{
	decl Float:fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(iClient, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}
ApplyRocketParameters()
{
	new iEntity = EntRefToEntIndex(g_iRocketEntity);
	decl Float:fAngles[3]; GetVectorAngles(g_fRocketDirection, fAngles);
	decl Float:fVelocity[3]; CopyVectors(g_fRocketDirection, fVelocity);
	ScaleVector(fVelocity, g_fRocketSpeed);
	SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
	SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}
public Action:ChangeParameter(client, args)
{
	decl String:arg1[16] = "", String:arg2[12] = "";
	GetCmdArg(1, arg1, sizeof(arg1));
	GetCmdArg(2, arg2, sizeof(arg2));
	new Float:parameter_value = StringToFloat(arg2);
	if (StrEqual(arg1, "ORBIT_START", false)) ORBIT_START = parameter_value;
	if (StrEqual(arg1, "ORBIT_DEFLECT", false)) ORBIT_DEFLECT = parameter_value;
	if (StrEqual(arg1, "SPEED_START", false)) SPEED_START = parameter_value;
	if (StrEqual(arg1, "SPEED_DEFLECT", false)) SPEED_DEFLECT = parameter_value;
	if (StrEqual(arg1, "DAMAGE_START", false)) DAMAGE_START = parameter_value;
	if (StrEqual(arg1, "DAMAGE_DEFLECT", false)) DAMAGE_DEFLECT = parameter_value;
	PrintToChatAll("%s : %s", arg1, arg2);
	return Plugin_Handled;
}
public Action:GenerateRate(client, args)
{
	ORBIT_START = GetRandomFloat(0.200, 0.300);
	ORBIT_DEFLECT = GetRandomFloat(0.0230, 0.0330);
	SPEED_START = GetRandomFloat(800.0, 1250.0);
	SPEED_DEFLECT = GetRandomFloat(298.0, 302.0);
	PrintToChatAll("New generate orbit and speed");
	FakeClientCommand(client, "sm_get_rate");
}
public Action:Get_rate(client, args)
{
	PrintToConsole(client, "%f\n%f\n%f\n%f\n%f\n%f", ORBIT_START, ORBIT_DEFLECT, SPEED_START, SPEED_DEFLECT, DAMAGE_START, DAMAGE_DEFLECT);
}
public Action:OnPlayerSpawn(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return;
	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if (!(iClass == TFClass_Pyro || iClass == TFClassType:TFClass_Unknown))
	{
		TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true);
		TF2_RespawnPlayer(iClient);
	}
}
public Action:OnPlayerDeath(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_iLastDeadTeam = GetClientTeam(iVictim);
}
public Action:OnPlayerInventory(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return;
	for (new iSlot = 1; iSlot < 5; iSlot++)
	{
		new iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if (iEntity != -1) RemoveEdict(iEntity);
	}
	new primary = GetPlayerWeaponSlot(iClient, TFWeaponSlot_Primary);
	if (primary == -1)
	{
		new Handle:item = TF2Items_CreateItem(OVERRIDE_ALL);
		TF2Items_SetClassname(item, "tf_weapon_flamethrower");
		TF2Items_SetItemIndex(item, 21);
		TF2Items_SetLevel(item, 100);
		TF2Items_SetQuality(item, 8);
		TF2Items_SetNumAttributes(item, 1);
		TF2Items_SetAttribute(item, 0, 254, 4.0);
		primary = TF2Items_GiveNamedItem(iClient, item);
		CloseHandle(item);
		EquipPlayerWeapon(iClient, primary);
	}
}
public Action:TF2Items_OnGiveNamedItem(client, String:classname[], iItemDefinitionIndex, &Handle:hItem)
{
	static Handle:item = INVALID_HANDLE;
	if (item != INVALID_HANDLE)
	{
		CloseHandle(item);
		item = INVALID_HANDLE;
	}
	if (StrEqual(classname, "tf_weapon_fireaxe") || StrEqual(classname, "tf_weapon_flaregun_revenge") || StrEqual(classname, "tf_weapon_shotgun_pyro") || StrEqual(classname, "tf_weapon_flaregun") || iItemDefinitionIndex == 741 || iItemDefinitionIndex == 215 || iItemDefinitionIndex == 40 || iItemDefinitionIndex == 594)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	iButtons &= ~IN_ATTACK;
}
public Action:OnRoundStart(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	g_iRocketSpeed = 0;
	if (g_hTimerHud != INVALID_HANDLE)
	{
		KillTimer(g_hTimerHud);
		g_hTimerHud = INVALID_HANDLE;
	}
	g_hTimerHud = CreateTimer(0.5, Timer_HudSpeed, _, TIMER_REPEAT);
}
public Action:Timer_HudSpeed(Handle:hTimer)
{
	SetHudTextParams(-1.0, 2.0, 0.5, 255, 255, 255, 255);
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient) && !IsFakeClient(iClient) && g_iRocketSpeed != 0)
		{
			ShowSyncHudText(iClient, g_hHud, "Speed: %i m/h || Deflection: %i", g_iRocketSpeed, g_iRocketDeflections);
		}
	}
}
public Action:OnRoundEnd(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if (g_hLogicTimer != INVALID_HANDLE)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;
	}
	if (g_hTimerHud != INVALID_HANDLE)
	{
		KillTimer(g_hTimerHud);
		g_hTimerHud = INVALID_HANDLE;
	}
	DestroyRocket();
}
public OnMapStart()
{
	g_iRocketCount = 0;
	g_bRocketIsValid = false;
	if (g_hLogicTimer != INVALID_HANDLE)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;
	}
}
public OnMapEnd()
{
	g_iRocketCount = 0;
	g_bRocketIsValid = false;
	if (g_hLogicTimer != INVALID_HANDLE)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;
	}
}
DestroyRocket()
{
	if (IsValidRocket() == true)
	{
		new iEntity = EntRefToEntIndex(g_iRocketEntity);
		if (iEntity && IsValidEntity(iEntity)) RemoveEdict(iEntity);
		g_bRocketIsValid = false;
		g_iRocketCount = 0;
	}
}
stock GetAnalogueTeam(iTeam)
{
	if (iTeam == 2) return 3;
	return 2;
}
public Action:OnStartTouch(entity, other)
{
	if (other >= 1 && other <= MaxClients)
	{
		Destroy_Rocket_Touch(entity);
		return Plugin_Continue;
	}
	if (GetEdictClassname(other, obj_destry, sizeof(obj_destry)) && strncmp(obj_destry, "obj_", 4, false) == 0)
	{
		Destroy_Rocket_Touch(entity);
		return Plugin_Continue;
	}
	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public Action:OnTouch(entity, other)
{
	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	CloseHandle(trace);
	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}
public bool:TEF_ExcludeEntity(entity, contentsMask, any:data)
{
	return (entity != data);
}
public Destroy_Rocket_Touch(entity)
{
	g_iRocketCount= 0;
	g_bRocketIsValid = false;
	new client;
	client = GetEntDataEnt2(entity, FindSendPropInfo("CPhysicsProp", "m_hOwnerEntity"));
	Say_Destoy_Rocket(client);
}
public Say_Destoy_Rocket(client)
{
	decl String:name[32];
	GetClientName(client, name, sizeof(name));
	decl String:colorname[] = "\x073EFF3E";
	if (client > 0){
		switch (GetClientTeam(client))
		{
			case 2: colorname = "\x07FF4040";
			case 3: colorname = "\x0799CCFF";
			default: colorname = "\x073EFF3E";
		}
	}
	PrintToChatAll("%s%s \x01: Speed: \x0799FF99%i\x01 || Deflection: \x0799FF99%i\x01", colorname, name, g_iRocketSpeed, g_iRocketDeflections);
}
stock SelectTarget(iTeam)
{
	new iTarget = -1;
	new Float:fTargetWeight = 0.0;
	decl Float:fRocketPosition[3];
	decl Float:fRocketDirection[3];
	decl Float:fWeight;
	new bool:bUseRocket;
	new iEntity = EntRefToEntIndex(g_iRocketEntity);
	if (iEntity != -1 && IsValidEntity(iEntity))
	{
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
		CopyVectors(g_fRocketDirection, fRocketDirection);
		fWeight = 25.0;
		bUseRocket = true;
	}
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (!IsValidClient(iClient, true)) continue;
		if (iTeam && GetClientTeam(iClient) != iTeam) continue;
		new Float:fNewWeight = GetRandomFloat(0.0, 100.0);
		
		if (bUseRocket == true)
		{
			decl Float:fClientPosition[3]; GetClientEyePosition(iClient, fClientPosition);
			decl Float:fDirectionToClient[3]; MakeVectorFromPoints(fRocketPosition, fClientPosition, fDirectionToClient);
			fNewWeight += GetVectorDotProduct(fRocketDirection, fDirectionToClient) * fWeight;
		}
		
		if ((iTarget == -1) || fNewWeight >= fTargetWeight)
		{
			iTarget = iClient;
			fTargetWeight = fNewWeight;
		}
	}
	return iTarget;
}
stock CopyVectors(Float:fFrom[3], Float:fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}
stock LerpVectors(Float:fA[3], Float:fB[3], Float:fC[3], Float:t)
{
	if (t < 0.0) t = 0.0;
	if (t > 1.0) t = 1.0;
	
	fC[0] = fA[0] + (fB[0] - fA[0]) * t;
	fC[1] = fA[1] + (fB[1] - fA[1]) * t;
	fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}
stock bool:BothTeamsPlaying()
{
	new bool:bRedFound, bool:bBluFound;
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient, true) == false) continue;
		new iTeam = GetClientTeam(iClient);
		if (iTeam == 2) bRedFound = true;
		if (iTeam == 3) bBluFound = true;
	}
	return bRedFound && bBluFound;
}
public Get_Rank_Info()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		Speed_record[client] = GetSpeed(client);
		Deflect_record[client] = GetDeflect(client);
	}
}
public Set_Record_Speed(client, Curr_Speed, Curr_Deflect)
{
	if (IsValidClient(client))
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
}
stock bool:IsValidClient(iClient, bool:bAlive = false)
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
bool:IsValidRocket()
{
	if (g_bRocketIsValid == true)
	{
		if (EntRefToEntIndex(g_iRocketEntity) == -1)
		{
			g_bRocketIsValid = false;
			g_iRocketCount = 0;
			return false;
		}
		return true;
	}
	return false;
}