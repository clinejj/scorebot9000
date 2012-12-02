package com.csoft.clinelympics;

import java.io.IOException;
import java.util.Date;
import java.util.logging.Logger;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.Key;
import com.google.appengine.api.datastore.KeyFactory;
import com.google.appengine.api.users.User;
import com.google.appengine.api.users.UserService;
import com.google.appengine.api.users.UserServiceFactory;

@SuppressWarnings("serial")
public class ScoreServlet extends HttpServlet {
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
    			throws IOException {
		String playerID = req.getParameter("playerID");
		int gameID = Integer.parseInt(req.getParameter("gameID").trim());
		int playerScore = Integer.parseInt(req.getParameter("playerScore").trim());
		Date date = new Date();
		
		Key scoreKey = KeyFactory.createKey("Scores", "scoreList");
		Entity score = new Entity("score", scoreKey);
		score.setProperty("playerID", playerID);
		score.setProperty("gameID", gameID);
		score.setProperty("playerScore", playerScore);
		score.setProperty("date", date);
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(score);
		
		resp.sendRedirect("/scores.jsp");
	}
}
