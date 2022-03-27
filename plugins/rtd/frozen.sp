/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*******************************//
//  -  Roll The Dice: Frozen  -  //
//*******************************//

int	g_iIceStatue[MAXPLAYERS+1]	= {0, ...};
int	g_iBaseFrozen[MAXPLAYERS+1]	= {255, ...};

void Frozen_Perk(int client, bool apply){

	if(apply)
		Frozen_ApplyPerk(client);
	
	else
		Frozen_RemovePerk(client);

}

void Frozen_ApplyPerk(int client){

	g_iBaseFrozen[client] = Frozen_GetEntityAlpha(client);
	Frozen_Set(client, 0);
	Frozen_DisarmWeapons(client, true);
	
	if(g_iIceStatue[client] < 1){
	
		g_iIceStatue[client] = CreateDummy(client);
		if(g_iIceStatue[client] > MaxClients && IsValidEntity(g_iIceStatue[client]))
			SetClientViewEntity(client, g_iIceStatue[client]);
	
	}
	
	SetEntityMoveType(client, MOVETYPE_NONE);
	SetVariantInt(1);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

void Frozen_RemovePerk(int client){
	
	SetClientViewEntity(client, client);
	
	if(g_iIceStatue[client] > MaxClients && IsValidEntity(g_iIceStatue[client]))
		AcceptEntityInput(g_iIceStatue[client], "Kill");
	
	g_iIceStatue[client] = 0;
	Frozen_Set(client, g_iBaseFrozen[client]);
	Frozen_DisarmWeapons(client, false);
	
	SetEntityMoveType(client, MOVETYPE_WALK);
	SetVariantInt(0);
	AcceptEntityInput(client, "SetForcedTauntCam");

}

int CreateDummy(client){

	int iRag = CreateEntityByName("tf_ragdoll");
	if(iRag < 1 || iRag <= MaxClients || !IsValidEntity(iRag))
		return 0;
	
	float fPos[3], fAng[3], fVel[3];
	GetClientAbsOrigin(client, fPos);
	GetClientAbsAngles(client, fAng);
	GetEntPropVector(client, Prop_Data, "m_vecVelocity", fVel);
	
	TeleportEntity(iRag, fPos, fAng, fVel);
	
	SetEntProp(iRag, Prop_Send, "m_iPlayerIndex", client);
	SetEntProp(iRag, Prop_Send, "m_bIceRagdoll", 1);
	SetEntProp(iRag, Prop_Send, "m_iTeam", GetClientTeam(client));
	SetEntProp(iRag, Prop_Send, "m_iClass", _:TF2_GetPlayerClass(client));
	SetEntProp(iRag, Prop_Send, "m_bOnGround", 1);
	
	//Scale fix by either SHADoW NiNE TR3S or ddhoward (dunno who was first :p)
	//https://forums.alliedmods.net/showpost.php?p=2383502&postcount=1491
	//https://forums.alliedmods.net/showpost.php?p=2366104&postcount=1487
	SetEntPropFloat(iRag, Prop_Send, "m_flHeadScale", GetEntPropFloat(client, Prop_Send, "m_flHeadScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flTorsoScale", GetEntPropFloat(client, Prop_Send, "m_flTorsoScale"));
	SetEntPropFloat(iRag, Prop_Send, "m_flHandScale", GetEntPropFloat(client, Prop_Send, "m_flHandScale"));
	
	SetEntityMoveType(iRag, MOVETYPE_NONE);
	
	DispatchSpawn(iRag);
	ActivateEntity(iRag);
	
	return iRag;

}

void Frozen_Set(int client, int iValue){
	
	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
	
	Frozen_SetEntityAlpha(client, iValue);
	
	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		if(GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
		
		Frozen_SetEntityAlpha(iWeapon, iValue);
	
	}
	
	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); i++){
	
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass))) continue;
		
		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
		
		Frozen_SetEntityAlpha(i, iValue);
	
	}

}

stock int Frozen_GetEntityAlpha(int entity){

	return GetEntData(entity, GetEntSendPropOffs(entity, "m_clrRender") + 3, 1);

}

stock void Frozen_SetEntityAlpha(int entity, int value){

	SetEntData(entity, GetEntSendPropOffs(entity, "m_clrRender") + 3, value, 1, true);

}

void Frozen_DisarmWeapons(int client, bool bDisarm){

	int iWeapon = 0;
	for(int i = 0; i < 3; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextPrimaryAttack",	bDisarm ? GetGameTime() + 86400.0 : 0.1);
		SetEntPropFloat(iWeapon, Prop_Data, "m_flNextSecondaryAttack",	bDisarm ? GetGameTime() + 86400.0 : 0.1);
	
	}

}