package com.csoft.clinelympics;

import java.io.IOException;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;

@SuppressWarnings("serial")
public class GameServlet extends HttpServlet {
    
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {	
		Game game = new Game(Integer.parseInt(req.getParameter("gameID")), req.getParameter("gameName").trim(), Boolean.parseBoolean(req.getParameter("scoreType").trim()));
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(game.createEntity());
		
		resp.sendRedirect("/games.jsp");
	}
}
