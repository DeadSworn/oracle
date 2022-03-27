/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*************************************//
//  -  Roll The Dice: Spawn Sentry  -  //
//*************************************//

bool	g_bCanSpawnSentry[MAXPLAYERS+1]	= {false, ...};
Handle	g_hSpawnedSentries[MAXPLAYERS+1]= INVALID_HANDLE;

int		g_iSentryLevel	= 2;
int		g_iSentryStay	= 0;
int		g_iMaxSentries	= 1;

void SpawnSentry_Proc(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_iSentryLevel	= StringToInt(sPieces[0]);
	g_iSentryStay	= StringToInt(sPieces[1]);
	g_iMaxSentries	= StringToInt(sPieces[2]);

}

void SpawnSentry_Perk(int client, bool apply){

	if(apply)
		SpawnSentry_ApplyPerk(client);

	else
		SpawnSentry_RemovePerk(client);

}

void SpawnSentry_ApplyPerk(int client){

	delete g_hSpawnedSentries[client];
	g_hSpawnedSentries[client] = CreateArray();

	g_bCanSpawnSentry[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Sentry_Initialization", LANG_SERVER, 0x03, 0x01);

}

void SpawnSentry_RemovePerk(int client){

	g_bCanSpawnSentry[client] = false;

	if(g_iSentryStay > 0){
	
		ClearArray(g_hSpawnedSentries[client]);
		return;
	
	}

	int iSize = GetArraySize(g_hSpawnedSentries[client]);
	for(int i = 0; i < iSize; i++){
	
		int iEnt = EntRefToEntIndex(GetArrayCell(g_hSpawnedSentries[client], i));
		if(iEnt > MaxClients && IsValidEntity(iEnt))
			AcceptEntityInput(iEnt, "Kill");
	
	}

	ClearArray(g_hSpawnedSentries[client]);

}

void SpawnSentry_Voice(int client){

	if(!g_bCanSpawnSentry[client])
		return;

	float fPos[3];
	if(GetClientLookPosition(client, fPos)){
	
		if(CanBuildAtPos(fPos, true)){
		
			float fSentryAng[3], fClientAng[3];
			GetClientEyeAngles(client, fClientAng);
		
			fSentryAng[1] = fClientAng[1];
			SpawnSentry_OnSpawned(client, SpawnSentry(client, fPos, fSentryAng, g_iSentryLevel > 0 ? g_iSentryLevel : 1, g_iSentryLevel < 1 ? true : false));
		
			int iSpawned = GetArraySize(g_hSpawnedSentries[client]);
			PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Sentry_Spawned", LANG_SERVER, 0x03, iSpawned, g_iMaxSentries, 0x01);
		
			if(iSpawned >= g_iMaxSentries)
				if(g_iSentryStay > 0)
					ForceRemovePerk(client);
				else
					g_bCanSpawnSentry[client] = false;
		
		}
	
	}

}

void SpawnSentry_OnSpawned(int client, int iSentry){

	int iSentryRef = EntIndexToEntRef(iSentry);
	PushArrayCell(g_hSpawnedSentries[client], iSentryRef);

	if(g_iSentryStay != 2)
		return;

	char sUserKillInput[32];
	Format(sUserKillInput, 32, "OnUser1 !self:kill::%d:1", GetPerkTime(12));
	SetVariantString(sUserKillInput);
	AcceptEntityInput(iSentry, "AddOutput");
	AcceptEntityInput(iSentry, "FireUser1");

}

/*
	The SpawnSentry stock is taken from Pelipoika's TF2 Building Spawner EXTREME
	https://forums.alliedmods.net/showthread.php?p=2148102
*/
stock int SpawnSentry(int builder, float Position[3], float Angle[3], int level, bool mini=false, bool disposable=false, int flags=4){

	float m_vecMinsMini[3] = {-15.0, -15.0, 0.0}, m_vecMaxsMini[3] = {15.0, 15.0, 49.5};
	float m_vecMinsDisp[3] = {-13.0, -13.0, 0.0}, m_vecMaxsDisp[3] = {13.0, 13.0, 42.9};
	
	int sentry = CreateEntityByName("obj_sentrygun");
	
	if(!IsValidEntity(sentry)) return 0;
	
	int iTeam = GetClientTeam(builder);
	
	SetEntPropEnt(sentry, Prop_Send, "m_hBuilder", builder);
	
	SetVariantInt(iTeam);
	AcceptEntityInput(sentry, "SetTeam");

	DispatchKeyValueVector(sentry, "origin", Position);
	DispatchKeyValueVector(sentry, "angles", Angle);
	
	if(mini){
	
		SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? iTeam : iTeam -2);
		DispatchSpawn(sentry);
		
		SetVariantInt(100);
		AcceptEntityInput(sentry, "SetHealth");
		
		SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.75);
		SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsMini);
		SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsMini);
	
	}else if(disposable){
	
		SetEntProp(sentry, Prop_Send, "m_bMiniBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_bDisposableBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", level == 1 ? iTeam : iTeam -2);
		DispatchSpawn(sentry);
		
		SetVariantInt(100);
		AcceptEntityInput(sentry, "SetHealth");
		
		SetEntPropFloat(sentry, Prop_Send, "m_flModelScale", 0.60);
		SetEntPropVector(sentry, Prop_Send, "m_vecMins", m_vecMinsDisp);
		SetEntPropVector(sentry, Prop_Send, "m_vecMaxs", m_vecMaxsDisp);
	
	}else{
	
		SetEntProp(sentry, Prop_Send, "m_iUpgradeLevel", level);
		SetEntProp(sentry, Prop_Send, "m_iHighestUpgradeLevel", level);
		SetEntProp(sentry, Prop_Data, "m_spawnflags", flags);
		SetEntProp(sentry, Prop_Send, "m_bBuilding", 1);
		SetEntProp(sentry, Prop_Send, "m_nSkin", iTeam -2);
		DispatchSpawn(sentry);
	
	}
	
	return sentry;

}