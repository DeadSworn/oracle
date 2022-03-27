/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***********************************//
//  -  Roll The Dice: Low Health  -  //
//***********************************//

int g_iLowHealth_Value = 7;

void LowHealth_Proc(const char[] sSettings){

	g_iLowHealth_Value = StringToInt(sSettings);

}

void LowHealth_Perk(int client){

	SetEntityHealth(client, g_iLowHealth_Value);

}