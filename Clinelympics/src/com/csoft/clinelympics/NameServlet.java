package com.csoft.clinelympics;

import java.io.IOException;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;

@SuppressWarnings("serial")
public class NameServlet extends HttpServlet {
	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		Name n = new Name(req.getParameter(Name.nameStr).trim());
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		datastore.put(n.createEntity());
		
		resp.sendRedirect("/names.jsp");
	}

}
