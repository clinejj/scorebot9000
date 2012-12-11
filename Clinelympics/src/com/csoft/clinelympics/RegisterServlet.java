package com.csoft.clinelympics;

import java.io.IOException;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;

@SuppressWarnings("serial")
public class RegisterServlet extends HttpServlet {
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {		
		Player player = new Player(req.getParameter(Player.playerIDName), 
				req.getParameter(Player.playerNameName).trim(), 
				req.getParameter(Player.teamNameName).trim());
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(player.createEntity());
		
		resp.sendRedirect("/players.jsp");
	}
}
