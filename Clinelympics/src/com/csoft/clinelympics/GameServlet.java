package com.csoft.clinelympics;

import java.io.IOException;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;

@SuppressWarnings("serial")
public class GameServlet extends HttpServlet {
    
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		int gameID = Integer.parseInt(req.getParameter("gameID"));
		String gameName = req.getParameter("gameName").trim();
		boolean scoreType = Boolean.parseBoolean(req.getParameter("scoreType").trim());
		
		Key gameKey = KeyFactory.createKey("Games", "gameList");
		Entity game = new Entity("game", gameKey);
		game.setProperty("gameID", gameID);
		game.setProperty("gameName", gameName);
		game.setProperty("scoreType", scoreType);
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(game);
		
		resp.sendRedirect("/games.jsp");
	}
}
