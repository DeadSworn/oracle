/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//******************************//
//  -  Roll The Dice: Vital  -  //
//******************************//

#define MAX_HEALTH_ATTRIB 26

int		g_iVital_Value = 150;
float	g_fVital_Value = 150.0;

void Vital_Proc(const char[] sSettings){

	g_fVital_Value = StringToFloat(sSettings);
	g_iVital_Value = RoundFloat(g_fVital_Value);

}

void Vital_Perk(int client, bool apply){

	if(apply)
		Vital_ApplyPerk(client);
	
	else
		TF2Attrib_RemoveByDefIndex(client, MAX_HEALTH_ATTRIB);

}

void Vital_ApplyPerk(int client){

	TF2Attrib_SetByDefIndex(client, MAX_HEALTH_ATTRIB, g_fVital_Value);

	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iHealth") +g_iVital_Value);

}