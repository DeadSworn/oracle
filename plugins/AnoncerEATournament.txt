#include <sourcemod>
#include <morecolors>
new NextMSG = 0;
public OnPluginStart()
{
	CreateTimer(20.0, Timer_Msg, _, TIMER_REPEAT);
}
public Action:Timer_Msg(Handle:timer, any:userid) // аВбаЗаОаВ аКаАаЖаДбаЕ 30 баЕаКбаНаД
{
	NextMSG++; // +1 аКаАаЖаДбаЕ 30 баЕаКбаНаД
	switch(NextMSG)
	{
		case 1,6,11:
		{
			CPrintToChatAll("{green}!tp{lightblue} and {green}!fp{default} - {lightblue}third-person, first-person view.");
		}
		case 2,7,12:
		{
			CPrintToChatAll("{orange}The 乇ﾑ tournament will start soon! check our steam community group {red}(!group) {orange}for more info!");
		}
		case 3,8,13:
		{
			CPrintToChatAll("{green}top{lightblue} and {green}top10{default} - {lightblue}Top players.");
			CPrintToChatAll("{green}rank{lightblue} and {green}!rank{default} - {lightblue}your Rank.");
			CPrintToChatAll("{green}session{default} - {lightblue}session stats.");
		}
		case 4,9,14:
		{
			CPrintToChatAll("{green}ts{lightblue} and {green}!ts{default} - {lightblue}Top speed.");
			CPrintToChatAll("{green}tc{lightblue} and {green}!tc{default} - {lightblue}your record Speed.");
		}
		case 5,10,15:
		{
			CPrintToChatAll("{green}!sc{lightblue} - {lightblue}play music.");
			CPrintToChatAll("{green}!scstop{lightblue} - {lightblue}stop music.")
		}
		case 16:
		{
			CPrintToChatAll("{green}!vj{lightblue} - {lightblue} 1 vs All mode.");
			CPrintToChatAll("{green}rtd{default} - {lightblue}random effects.");
		}
		case 17:
		{
			CPrintToChatAll("{green}!votepvb{default} - {lightblue}Enable/Disable mode player vs bot.");
			CPrintToChatAll("{lightblue}Type {green}!group {lightblue}to join the community!");
			CPrintToChatAll("{lightblue}Type {green}!clan {lightblue}to check out our clan!");
		}
		case 18:
		{
			CPrintToChatAll("{green}!menu{default} - {lightblue}Custom menu");
			CPrintToChatAll("{green}!call <message> {default} - {lightblue}call admin");
			NextMSG = 0;
		}
	}
}