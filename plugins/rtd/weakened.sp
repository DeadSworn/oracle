/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*********************************//
//  -  Roll The Dice: Weakened  -  //
//*********************************//

float g_fWeakenedMultiplayer = 2.5;

void Weakened_Proc(const char[] sSettings){

	g_fWeakenedMultiplayer = StringToFloat(sSettings);

}

void Weakened_Perk(int client, bool apply){

	if(apply)
		SDKHook(client, SDKHook_OnTakeDamage, Weakened_OnTakeDamage);
	
	else
		SDKUnhook(client, SDKHook_OnTakeDamage, Weakened_OnTakeDamage);

}

public Action Weakened_OnTakeDamage(int iVic, int &iAttacker, int &iInflictor, float &fDamage, int &iDamageType){

	if(iVic == iAttacker)	
		return Plugin_Continue;
	
	fDamage *= g_fWeakenedMultiplayer;
	
	return Plugin_Changed;

}