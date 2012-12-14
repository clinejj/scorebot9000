package com.csoft.clinelympics;

import java.io.IOException;
import java.util.List;

import javax.servlet.http.HttpServlet;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import com.google.appengine.api.datastore.DatastoreService;
import com.google.appengine.api.datastore.DatastoreServiceFactory;
import com.google.appengine.api.datastore.Entity;
import com.google.appengine.api.datastore.FetchOptions;
import com.google.appengine.api.datastore.Query;

@SuppressWarnings("serial")
public class InstallServlet extends HttpServlet {

	public void doPost(HttpServletRequest req, HttpServletResponse resp)
	throws IOException {
		Settings s = new Settings((String) req.getParameter(Settings.adminName),
				(String) req.getParameter(Settings.adminNumName), 
				-1,
				(String) req.getParameter(Settings.siteNameName));
		
		DatastoreService datastore = DatastoreServiceFactory.getDatastoreService();
		Query query = new Query(Settings.entityKind, s.getSettingsKey());
		List<Entity> sList = datastore.prepare(query).asList(FetchOptions.Builder.withDefaults());
		if (sList.isEmpty()) {
			datastore.put(s.createEntity());
		}
		
		resp.sendRedirect("/admin.jsp");
	}
}