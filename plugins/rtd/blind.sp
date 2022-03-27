/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd2.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//******************************//
//  -  Roll The Dice: Blind  -  //
//******************************//

UserMsg	g_BlindMsgId;
int		g_iBlind_Value = 250;

void Blind_Proc(const char[] sSettings){

	g_iBlind_Value = StringToInt(sSettings);

}

void Blind_Start(){

	g_BlindMsgId = GetUserMessageId("Fade");

}

void Blind_Perk(int client, bool apply){

	if(IsFakeClient(client))
		return;

	int iTargets[2];
	iTargets[0] = client;

	Handle hMsg = StartMessageEx(g_BlindMsgId, iTargets, 1);
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, 1536);
	BfWriteShort(hMsg, apply ? (0x0002 | 0x0008) : (0x0001 | 0x0010));
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, 0);
	BfWriteByte(hMsg, apply ? g_iBlind_Value : 0);

	EndMessage();

}