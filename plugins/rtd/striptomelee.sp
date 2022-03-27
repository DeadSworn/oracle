/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***************************************//
//  -  Roll The Dice: Strip to Melee  -  //
//***************************************//

int g_iStripToMelee_RegainHealth = 1;

void StripToMelee_Proc(const char[] sSettings){

	g_iStripToMelee_RegainHealth = StringToInt(sSettings);

}

void StripToMelee_Perk(int client, bool apply){

	if(!apply)
		return;

	TF2_RemoveWeaponSlot(client, 0);
	TF2_RemoveWeaponSlot(client, 1);
	
	int iWeapon = GetPlayerWeaponSlot(client, 2);
	if(iWeapon > MaxClients && IsValidEntity(iWeapon))
		SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", iWeapon);
	
	TF2_RemoveWeaponSlot(client, 3);
	TF2_RemoveWeaponSlot(client, 4);

	if(g_iStripToMelee_RegainHealth > 0)
		SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iMaxHealth"));

}