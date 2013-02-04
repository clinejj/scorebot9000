Scorebot 9000 is a roll-your-own score tracking system that runs on Google AppEngine. It allows a player to register and submit scores to the system via text message and Twilio. Administrators can login to the system, setup events, create games used for scoring, and manage players and scores.

Created by John Cline (@clinejj on twitter).

To setup:
1) Create a site on Google AppEngine.
2) Download Scorebot 9000.
3) Import the Scorebot 9000 folder as a new project into the Eclipse workspace.
4) Change the appengine-web.xml file in the war/WEB-INF folder to match your AppEngine settings (specifically the application and version numbers).
5) Adjust any other settings as needed in the site (such as the index.jsp file).
6) Deploy to Google AppEngine.
7) Visit the http://your-app-name.appspot.com/install.jsp to setup the administration account and start creating events.
8) To use Twilio, direct your phone number to send texts to http://your-app-name.appspot.com/inbound

Usage:
Once the site has been setup, create an event and games. The "current event" is used for site display, and controls which event is displayed by default when the "scores" and "medals" pages are clicked. If an event is "active," it is currently running and the system will respond to any texts sent. Players can register, submit scores, and change teams/names as applicable. If team scoring is used, teams must be the same size. The administration phone number used during setup can start and stop an event at any time. "Archived" events will not show up in the "summary" drop down menu.

Also be sure to create several "names" for the system to assign to players using "Names" tab on the admin panel.


 