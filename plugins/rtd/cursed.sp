/*

This script is a part of RTD2 plugin and is not meant to work by itself.
If you were to edit anything here, you'd have to recompile rtd.sp instead of this one.

Although, you SHOULD NOT edit anything here. If you need to change something, look up how to override a perk:
https://forums.alliedmods.net/showpost.php?p=2389730&postcount=2

Link to the thread:
https://forums.alliedmods.net/showthread.php?t=278579

*/

//*******************************//
//  -  Roll The Dice: Cursed  -  //
//*******************************//

/*
	This perk's behaviour is taken from Farbror Godis' Curse
	https://forums.alliedmods.net/showthread.php?p=2401008
*/

bool g_bIsCursed[MAXPLAYERS+1] = {false, ...};

void Cursed_Perk(int client, bool apply){

	g_bIsCursed[client] = apply;

}

bool Cursed_OnPlayerRunCmd(int client, int &iButtons, float fVel[3]){

	if(!g_bIsCursed[client])
		return false;
	
	fVel[0] = -fVel[0];
	fVel[1] = -fVel[1];
	
	if(iButtons & IN_MOVELEFT){
	
		iButtons &= ~IN_MOVELEFT;
		iButtons |= IN_MOVERIGHT;
		
	}else if(iButtons & IN_MOVERIGHT){
	
		iButtons &= ~IN_MOVERIGHT;
		iButtons |= IN_MOVELEFT;
	
	}
	
	if(iButtons & IN_FORWARD){
	
		iButtons &= ~IN_FORWARD;
		iButtons |= IN_BACK;
	
	}else if(iButtons & IN_BACK){
	
		iButtons &= ~IN_BACK;
		iButtons |= IN_FORWARD;
	
	}
	
	return true;

}