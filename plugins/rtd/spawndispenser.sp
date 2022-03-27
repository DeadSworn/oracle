/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//****************************************//
//  -  Roll The Dice: Spawn Dispenser  -  //
//****************************************//

bool	g_bCanSpawnDispenser[MAXPLAYERS+1]	= {false, ...};
Handle	g_hSpawnedDispensers[MAXPLAYERS+1]	= INVALID_HANDLE;

int		g_iDispenserLevel		= 2;
int		g_bDispenserStayMode	= 1;
int		g_iMaxDispensers		= 1;

void SpawnDispenser_Proc(const char[] sSettings){

	char[][] sPieces = new char[3][8];
	ExplodeString(sSettings, ",", sPieces, 3, 8);

	g_iDispenserLevel		= StringToInt(sPieces[0]);
	g_bDispenserStayMode	= StringToInt(sPieces[1]);
	g_iMaxDispensers		= StringToInt(sPieces[2]);

}

void SpawnDispenser_Perk(int client, bool apply){

	if(apply)
		SpawnDispenser_ApplyPerk(client);
	
	else
		SpawnDispenser_RemovePerk(client);

}

void SpawnDispenser_ApplyPerk(int client){

	delete g_hSpawnedDispensers[client];
	g_hSpawnedDispensers[client] = CreateArray();

	g_bCanSpawnDispenser[client] = true;
	PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Dispenser_Initialization", LANG_SERVER, 0x03, 0x01);

}

void SpawnDispenser_RemovePerk(int client){

	g_bCanSpawnDispenser[client] = false;

	if(g_bDispenserStayMode > 0){
	
		ClearArray(g_hSpawnedDispensers[client]);
		return;
	
	}

	int iSize = GetArraySize(g_hSpawnedDispensers[client]);
	for(int i = 0; i < iSize; i++){
	
		int iEnt = EntRefToEntIndex(GetArrayCell(g_hSpawnedDispensers[client], i));
		
		if(iEnt > MaxClients && IsValidEntity(iEnt))
			AcceptEntityInput(iEnt, "Kill");
	
	}

	ClearArray(g_hSpawnedDispensers[client]);

}

void SpawnDispenser_Voice(int client){

	if(!g_bCanSpawnDispenser[client])
		return;

	float fPos[3];
	if(GetClientLookPosition(client, fPos)){
	
		if(CanBuildAtPos(fPos, false)){
		
			float fDispenserAng[3], fClientAng[3];
			GetClientEyeAngles(client, fClientAng);
		
			fDispenserAng[1] = fClientAng[1];
			SpawnDispenser_OnSpawned(client, SpawnDispenser(client, fPos, fDispenserAng, g_iDispenserLevel));
		
			int iSpawned = GetArraySize(g_hSpawnedDispensers[client]);
			PrintToChat(client, "%s %T", "\x07FFD700[RTD]\x01", "RTD2_Perk_Dispenser_Spawned", LANG_SERVER, 0x03, iSpawned, g_iMaxDispensers, 0x01);
		
			if(iSpawned >= g_iMaxDispensers)
				if(g_bDispenserStayMode > 0)
					ForceRemovePerk(client);
				else
					g_bCanSpawnDispenser[client] = false;
		
		}
	
	}

}

void SpawnDispenser_OnSpawned(int client, int iDispenser){

	int iDispenserRef = EntIndexToEntRef(iDispenser);
	PushArrayCell(g_hSpawnedDispensers[client], iDispenserRef);

	if(g_bDispenserStayMode != 2)
		return;

	char sUserKillInput[32];
	Format(sUserKillInput, 32, "OnUser1 !self:kill::%d:1", GetPerkTime(30));
	SetVariantString(sUserKillInput);
	AcceptEntityInput(iDispenser, "AddOutput");
	AcceptEntityInput(iDispenser, "FireUser1");

}

/*
	The SpawnDispenser stock is taken from Pelipoika's TF2 Building Spawner EXTREME
	https://forums.alliedmods.net/showthread.php?p=2148102
*/
stock int SpawnDispenser(int builder, float Position[3], float Angle[3], int level, int flags=4){

	int dispenser = CreateEntityByName("obj_dispenser");

	if(!IsValidEntity(dispenser)) return 0;

	int iTeam = GetClientTeam(builder);

	DispatchKeyValueVector(dispenser, "origin", Position);
	DispatchKeyValueVector(dispenser, "angles", Angle);
	SetEntProp(dispenser, Prop_Send, "m_iHighestUpgradeLevel", level);
	SetEntProp(dispenser, Prop_Data, "m_spawnflags", flags);
	SetEntProp(dispenser, Prop_Send, "m_bBuilding", 1);
	DispatchSpawn(dispenser); 

	SetVariantInt(iTeam);
	AcceptEntityInput(dispenser, "SetTeam");
	SetEntProp(dispenser, Prop_Send, "m_nSkin", iTeam -2);

	ActivateEntity(dispenser);
	SetEntPropEnt(dispenser, Prop_Send, "m_hBuilder", builder);

	return dispenser;

}