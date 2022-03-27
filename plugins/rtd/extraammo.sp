/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***********************************//
//  -  Roll The Dice: Extra Ammo  -  //
//***********************************//

int		g_iExtraAmmoOffsetClip, g_iExtraAmmoOffsetAmmo, g_iExtraAmmoOffsetAmmoType;
float	g_fExtraAmmo_Multiplier = 5.0;

void ExtraAmmo_Proc(const char[] sSettings){

	g_fExtraAmmo_Multiplier = StringToFloat(sSettings);

}

void ExtraAmmo_Start(){

	g_iExtraAmmoOffsetClip		= FindSendPropInfo("CTFWeaponBase", "m_iClip1");
	g_iExtraAmmoOffsetAmmo		= FindSendPropInfo("CTFPlayer", "m_iAmmo");
	g_iExtraAmmoOffsetAmmoType	= FindSendPropInfo("CBaseCombatWeapon", "m_iPrimaryAmmoType");

}

void ExtraAmmo_Perk(int client){
	
	int iWeapon = -1;
	for(int i = 0; i < 2; i++){
	
		iWeapon = GetPlayerWeaponSlot(client, i);
		
		if(iWeapon <= MaxClients || !IsValidEntity(iWeapon))
			continue;
		
		ExtraAmmo_MultiplyAmmo(client, iWeapon);
	
	}

}

void ExtraAmmo_MultiplyAmmo(int client, int iWeapon){

	switch(GetEntProp(iWeapon, Prop_Send, "m_iItemDefinitionIndex")){
	
		case 441,442,588:{
			SetEntPropFloat(iWeapon, Prop_Send, "m_flEnergy", 20.0 *g_fExtraAmmo_Multiplier);
		
		}
		
		default:{
		
			int iClip = ExtraAmmo_GetClip(iWeapon);
			if(iClip > -1)
				ExtraAmmo_SetClip(iWeapon, iClip < 1 ? RoundFloat(g_fExtraAmmo_Multiplier) : RoundFloat(float(iClip) *g_fExtraAmmo_Multiplier));
		
			int iAmmo = ExtraAmmo_GetAmmo(client, iWeapon);
			if(iAmmo > -1)
				ExtraAmmo_SetAmmo(client, iWeapon, iAmmo < 1 ? RoundFloat(g_fExtraAmmo_Multiplier) : RoundFloat(float(iAmmo) *g_fExtraAmmo_Multiplier));
		
		}
	
	}

}

//The bellow are ripped straight from the original RTD

int ExtraAmmo_SetAmmo(int client, int iWeapon, int iAmount){

	return SetEntData(client, g_iExtraAmmoOffsetAmmo + GetEntData(iWeapon, g_iExtraAmmoOffsetAmmoType, 1) * 4, iAmount);

}

int ExtraAmmo_GetAmmo(int client, int iWeapon){

	int iAmmoType = GetEntData(iWeapon, g_iExtraAmmoOffsetAmmoType, 1);
	if(iAmmoType == 4) return -1;
	
	return GetEntData(client, g_iExtraAmmoOffsetAmmo + iAmmoType * 4);

}

int ExtraAmmo_SetClip(int iWeapon, int iAmount){

	return SetEntData(iWeapon, g_iExtraAmmoOffsetClip, iAmount, _, true);

}

int ExtraAmmo_GetClip(int iWeapon){

	return GetEntData(iWeapon, g_iExtraAmmoOffsetClip);

}