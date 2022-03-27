/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*************************************//
//  -  Roll The Dice: Invisibility  -  //
//*************************************//

/*
	TODO: IF YOU TELL ME HOW TO GET THE INSIDE OF THE B.A.S.E. JUMPER TO DISAPPEAR I WILL LOVE YOU FOREVER
*/

int		g_iBaseAlpha[MAXPLAYERS+1]	= {255, ...};
bool	g_bBaseSentry[MAXPLAYERS+1]	= {true, ...};
bool	g_bHasInvis[MAXPLAYERS+1]	= {false, ...};
int		g_iInvisValue				= 0;

void Invisibility_Proc(const char[] sSettings){

	g_iInvisValue = StringToInt(sSettings);

}

void Invisibility_Start(){

	HookEvent("post_inventory_application", Event_Invisibility_Resupply, EventHookMode_Post);

}

void Invisibility_Perk(int client, bool apply){

	if(apply)
		Invisibility_ApplyPerk(client);

	else
		Invisibility_RemovePerk(client);

}

void Invisibility_ApplyPerk(int client){

	g_bHasInvis[client]		= true;
	
	g_iBaseAlpha[client]	= GetEntityAlpha(client);
	g_bBaseSentry[client]	= (GetEntityFlags(client) & FL_NOTARGET) ? true : false;
	
	Invisibility_Set(client, g_iInvisValue);
	
	SetSentryTarget(client, false);

}

void Invisibility_RemovePerk(int client){

	g_bHasInvis[client]		= false;
	
	Invisibility_Set(client, g_iBaseAlpha[client]);
	
	SetSentryTarget(client, g_bBaseSentry[client]);

}

void Invisibility_Set(int client, int iValue){

	if(GetEntityRenderMode(client) == RENDER_NORMAL)
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);

	SetEntityAlpha(client, iValue);

	int iWeapon = 0;
	for(int i = 0; i < 5; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
	
		if(GetEntityRenderMode(iWeapon) == RENDER_NORMAL)
			SetEntityRenderMode(iWeapon, RENDER_TRANSCOLOR);
	
		SetEntityAlpha(iWeapon, iValue);
	
	}

	char sClass[24];
	for(int i = MaxClients+1; i < GetMaxEntities(); i++){
	
		if(!IsCorrectWearable(client, i, sClass, sizeof(sClass)))
			continue;
	
		if(GetEntityRenderMode(i) == RENDER_NORMAL)
			SetEntityRenderMode(i, RENDER_TRANSCOLOR);
	
		SetEntityAlpha(i, iValue);
	
	}

}

public void Event_Invisibility_Resupply(Handle hEvent, const char[] sEventName, bool bDontBroadcast){

	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(!IsValidClient(client))
		return;
	
	if(!g_bHasInvis[client])
		return;
	
	Invisibility_Set(client, g_iInvisValue);

}

stock int GetEntityAlpha(int iEntity){

	return GetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, 1);

}

stock void SetEntityAlpha(int iEntity, int iValue){

	SetEntData(iEntity, GetEntSendPropOffs(iEntity, "m_clrRender") + 3, iValue, 1, true);

}

bool IsCorrectWearable(int client, int i, char[] sClass, iBufferSize){

	if(!IsValidEntity(i))
		return false;

	GetEntityClassname(i, sClass, iBufferSize);
	if(StrContains(sClass, "tf_wearable", false) < 0 && StrContains(sClass, "tf_powerup", false) < 0)
		return false;

	if(GetEntPropEnt(i, Prop_Send, "m_hOwnerEntity") != client)
		return false;

	return true;

}

void SetSentryTarget(int client, bool bTarget){

	int iFlags = GetEntityFlags(client);	
	if(bTarget)
		SetEntityFlags(client, iFlags &~ FL_NOTARGET);
	else
		SetEntityFlags(client, iFlags | FL_NOTARGET);

}