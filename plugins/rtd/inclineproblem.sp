/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//****************************************//
//  -  Roll The Dice: Incline Problem  -  //
//****************************************//

float g_fDefaultStepSize[MAXPLAYERS+1] = {0.0, ...};

void InclineProblem_Perk(int client, bool apply){

	if(apply){
	
		g_fDefaultStepSize[client] = GetEntPropFloat(client, Prop_Send, "m_flStepSize");
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", 1.0);
	
	}else
		SetEntPropFloat(client, Prop_Send, "m_flStepSize", g_fDefaultStepSize[client]);

}