/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//***********************************//
//  -  Roll The Dice: Earthquake  -  //
//***********************************//

UserMsg g_EarthquakeMsgId;

float	g_fEarthquake_Amplitude = 25.0;
float	g_fEarthquake_Frequency = 25.0;

void Earthquake_Proc(const char[] sSettings){

	char[][] sPieces = new char[2][8];
	ExplodeString(sSettings, ",", sPieces, 2, 8);

	g_fEarthquake_Amplitude = StringToFloat(sPieces[0]);
	g_fEarthquake_Frequency = StringToFloat(sPieces[1]);

}

void Earthquake_Start(){

	g_EarthquakeMsgId = GetUserMessageId("Shake");

}

void Earthquake_Perk(int client, bool apply){

	if(IsFakeClient(client))
		return;

	if(!apply)
		return;

	int iClients[2];
	iClients[0] = client;

	Handle hMsg = StartMessageEx(g_EarthquakeMsgId, iClients, 1);

	BfWriteByte(hMsg, 0);
	BfWriteFloat(hMsg, g_fEarthquake_Amplitude);
	BfWriteFloat(hMsg, g_fEarthquake_Frequency);
	BfWriteFloat(hMsg, float(GetPerkTime(27)));

	EndMessage();

}