/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***************************************//
//  -  Roll The Dice: Lucky Sandvich  -  //
//***************************************//

bool	g_bLuckySandvich_HasCrit[MAXPLAYERS+1] = {false, ...};
int		g_iLuckySandvich_Health = 1000;

void LuckySandvich_Proc(const char[] sSettings){

	g_iLuckySandvich_Health = StringToInt(sSettings);

}

void LuckySandvich_Perk(int client){

	SetEntityHealth(client, GetEntProp(client, Prop_Data, "m_iHealth") +g_iLuckySandvich_Health);
	g_bLuckySandvich_HasCrit[client] = true;

}

bool LuckySandvich_SetCritical(int client){

	if(!g_bLuckySandvich_HasCrit[client])
		return false;
	
	g_bLuckySandvich_HasCrit[client] = false;
	return true;

}