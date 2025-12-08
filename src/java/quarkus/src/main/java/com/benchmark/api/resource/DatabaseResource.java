package com.benchmark.api.resource;

import com.benchmark.api.model.ComplexOrderResult;
import com.benchmark.api.model.User;
import com.benchmark.api.service.DatabaseService;
import io.smallrye.mutiny.Uni;
import jakarta.inject.Inject;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.QueryParam;
import jakarta.ws.rs.core.MediaType;
import jakarta.ws.rs.core.Response;

import java.time.Instant;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Path("/db")
@Produces(MediaType.APPLICATION_JSON)
public class DatabaseResource {

    @Inject
    DatabaseService databaseService;

    @Path("/simple")
    @GET
    public Uni<Response> getSimple(@QueryParam("id") Integer id) {
        if (id == null) {
            id = 1;
        }

        return databaseService.findUserById(id)
                .onItem().ifNull().continueWith(() -> {
                    Map<String, Object> error = new HashMap<>();
                    error.put("error", "User not found");
                    error.put("id", id);
                    return Response.status(404).entity(error).build();
                })
                .onItem().ifNotNull().transform(user -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("user", user);
                    response.put("timestamp", Instant.now().toString());
                    return Response.ok(response).build();
                });
    }

    @Path("/complex")
    @GET
    public Uni<Response> getComplex(@QueryParam("days") Integer days) {
        if (days == null) {
            days = 30;
        }

        return databaseService.findComplexOrders(days)
                .map(orders -> {
                    Map<String, Object> response = new HashMap<>();
                    response.put("orders", orders);
                    response.put("count", orders.size());
                    response.put("days", days);
                    response.put("timestamp", Instant.now().toString());
                    return Response.ok(response).build();
                })
                .onFailure().recoverWithItem(t -> {
                    Map<String, Object> error = new HashMap<>();
                    error.put("error", "Database error: " + t.getMessage());
                    return Response.status(500).entity(error).build();
                });
    }
}
