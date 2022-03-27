/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**********************************//
//  -  Roll The Dice: PowerPlay  -  //
//**********************************//

void PowerPlay_Perk(int client, bool apply){

	if(apply)
		PowerPlay_ApplyPerk(client);
	
	else
		PowerPlay_RemovePerk(client);

}

void PowerPlay_ApplyPerk(int client){

	TF2_AddCondition(client, TFCond_UberchargedCanteen);
	TF2_AddCondition(client, TFCond_CritOnFirstBlood);
	TF2_AddCondition(client, TFCond_UberBulletResist);
	TF2_AddCondition(client, TFCond_UberBlastResist);
	TF2_AddCondition(client, TFCond_UberFireResist);
	TF2_AddCondition(client, TFCond_MegaHeal);
	TF2_SetPlayerPowerPlay(client, true);

}

void PowerPlay_RemovePerk(int client){

	TF2_RemoveCondition(client, TFCond_UberchargedCanteen);
	TF2_RemoveCondition(client, TFCond_CritOnFirstBlood);
	TF2_RemoveCondition(client, TFCond_UberBulletResist);
	TF2_RemoveCondition(client, TFCond_UberBlastResist);
	TF2_RemoveCondition(client, TFCond_UberFireResist);
	TF2_RemoveCondition(client, TFCond_MegaHeal);
	TF2_SetPlayerPowerPlay(client, false);

}