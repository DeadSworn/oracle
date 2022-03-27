/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//**********************************//
//  -  Roll The Dice: Bad Sauce  -  //
//**********************************//

float g_fBadSauce_MilkDur	= 0.0;
float g_fBadSauce_JarateDur	= 0.0;
float g_fBadSauce_BleedDur	= 5.0;
float g_fBadSauce_PerkDur	= 25.0;

void BadSauce_Proc(const char[] sSettings){

	char[][] sPieces = new char[3][4];
	ExplodeString(sSettings, ",", sPieces, 3, 4);

	g_fBadSauce_MilkDur		= StringToFloat(sPieces[0]);
	g_fBadSauce_JarateDur	= StringToFloat(sPieces[1]);
	g_fBadSauce_BleedDur	= StringToFloat(sPieces[2]);
	g_fBadSauce_PerkDur		= float(GetPerkTime(29));

}

void BadSauce_Perk(int client, bool bApply){

	if(!bApply)
		return;

	if(g_fBadSauce_MilkDur >= 0.0)
		TF2_AddCondition	(client, TFCond_Milked,		g_fBadSauce_MilkDur		> 0.0	? g_fBadSauce_MilkDur	: g_fBadSauce_PerkDur);

	if(g_fBadSauce_JarateDur >= 0.0)
		TF2_AddCondition	(client, TFCond_Jarated,	g_fBadSauce_JarateDur	> 0.0	? g_fBadSauce_JarateDur	: g_fBadSauce_PerkDur);

	if(g_fBadSauce_BleedDur >= 0.0)
		TF2_MakeBleed		(client, client,			g_fBadSauce_BleedDur	> 0.0	? g_fBadSauce_BleedDur	: g_fBadSauce_PerkDur);

}