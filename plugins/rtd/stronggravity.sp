/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***************************************//
//  -  Roll The Dice: Strong Gravity  -  //
//***************************************//

float g_fBaseStrongGravity[MAXPLAYERS+1] = {0.0, ...};
float g_fStringGravity_Multiplier = 4.0;

void StrongGravity_Proc(const char[] sSettings){

	g_fStringGravity_Multiplier = StringToFloat(sSettings);

}

void StrongGravity_Perk(int client, bool apply){

	if(apply)
		StrongGravity_ApplyPerk(client);
	
	else
		SetEntityGravity(client, g_fBaseStrongGravity[client]);

}

void StrongGravity_ApplyPerk(int client){

	g_fBaseStrongGravity[client] = GetEntityGravity(client);
	SetEntityGravity(client, g_fStringGravity_Multiplier);

}