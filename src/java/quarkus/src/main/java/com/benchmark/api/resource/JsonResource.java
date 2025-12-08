package com.benchmark.api.resource;

import com.benchmark.api.model.JsonItem;
import jakarta.ws.rs.GET;
import jakarta.ws.rs.Path;
import jakarta.ws.rs.Produces;
import jakarta.ws.rs.core.MediaType;

import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Path("/json")
@Produces(MediaType.APPLICATION_JSON)
public class JsonResource {

    @GET
    public Map<String, Object> get() {
        List<JsonItem> items = new ArrayList<>(1000);
        for (int i = 0; i < 1000; i++) {
            items.add(new JsonItem(i));
        }

        Map<String, Object> response = new HashMap<>();
        response.put("items", items);
        response.put("count", items.size());
        response.put("timestamp", Instant.now().toString());

        return response;
    }
}
