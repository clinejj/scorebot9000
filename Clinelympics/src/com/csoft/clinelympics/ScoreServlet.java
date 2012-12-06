package com.csoft.clinelympics;

import java.io.IOException;
import javax.servlet.http.*;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;

@SuppressWarnings("serial")
public class ScoreServlet extends HttpServlet {
	
    public void doPost(HttpServletRequest req, HttpServletResponse resp)
    			throws IOException {
		Score score = new Score(req.getParameter("playerID"), Integer.parseInt(req.getParameter("gameID").trim()), Integer.parseInt(req.getParameter("playerScore").trim()));
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(score.createEntity());
		
		resp.sendRedirect("/scores.jsp");
	}
}
