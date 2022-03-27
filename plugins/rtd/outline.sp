/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//********************************//
//  -  Roll The Dice: Outline  -  //
//********************************//

bool g_bOutlined_Outline[MAXPLAYERS+1] = {false, ...};

void Outline_Perk(int client, bool apply){

	if(apply)
		Outline_ApplyPerk(client);
	
	else
		Outline_RemovePerk(client);

}

void Outline_ApplyPerk(int client){

	g_bOutlined_Outline[client] = view_as<bool>(GetEntProp(client, Prop_Send, "m_bGlowEnabled"));

	if(g_bOutlined_Outline[client])
		return;

	SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);

}

void Outline_RemovePerk(int client){

	if(!g_bOutlined_Outline[client])
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 0);

}