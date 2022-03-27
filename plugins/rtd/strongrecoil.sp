/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**************************************//
//  -  Roll The Dice: Strong Recoil  -  //
//**************************************//

bool g_bHasStrongRecoil[MAXPLAYERS+1] = {false, ...};

void StrongRecoil_Perk(int client, bool apply){

	g_bHasStrongRecoil[client] = apply;

}

void StrongRecoil_CritCheck(int client, int iWeapon){

	if(!g_bHasStrongRecoil[client])
		return;

	if(GetPlayerWeaponSlot(client, 2) == iWeapon)
		return;
	
	float fShake[3];
	fShake[0] = GetRandomFloat(-20.0, -80.0);
	fShake[1] = GetRandomFloat(-25.0, 25.0);
	fShake[2] = GetRandomFloat(-25.0, 25.0);
	SetEntPropVector(client, Prop_Send, "m_vecPunchAngle", fShake);

}