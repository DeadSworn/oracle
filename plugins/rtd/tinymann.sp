/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**********************************//
//  -  Roll The Dice: Tiny Mann  -  //
//**********************************//

float	g_fBaseTinyMann[MAXPLAYERS+1]	= {1.0, ...};
float	g_fTinyMannScale				= 0.15;

void TinyMann_Proc(const char[] sSettings){

	g_fTinyMannScale = StringToFloat(sSettings);

}

void TinyMann_Perk(int client, bool apply){

	if(apply)
		TinyMann_ApplyPerk(client);

	else
		TinyMann_RemovePerk(client);

}

void TinyMann_ApplyPerk(int client){

	TF2Attrib_SetByDefIndex(client, 2048, 1/g_fTinyMannScale/2);
	g_fBaseTinyMann[client] = GetEntPropFloat(client, Prop_Send, "m_flModelScale");
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fTinyMannScale);

}

void TinyMann_RemovePerk(int client){

	TF2Attrib_RemoveByDefIndex(client, 2048);
	SetEntPropFloat(client, Prop_Send, "m_flModelScale", g_fBaseTinyMann[client]);

	FixPotentialStuck(client);

}