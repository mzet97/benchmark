package com.benchmark.controller

import com.benchmark.Canonical

import org.springframework.web.bind.annotation.GetMapping
import org.springframework.web.bind.annotation.RequestParam
import org.springframework.web.bind.annotation.RestController

@RestController
class JsonController {

    /**
     * The previous implementation emitted {id,name,email,active,tags} -- a
     * shape no other implementation used, with a three-element list per item
     * that inflated the payload -- and ignored ?n=.
     */
    @GetMapping("/json")
    fun json(@RequestParam(name = "n", required = false) n: String?): Map<String, Any> =
        Canonical.response(n)
}
