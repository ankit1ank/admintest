import Vapor
import VaporPostgreSQL

let drop = Droplet()
try drop.addProvider(VaporPostgreSQL.Provider.self)
drop.preparations.append(Acronym.self)
(drop.view as? LeafRenderer)?.stem.cache = nil

drop.get("version") { request in
    if let db = drop.database?.driver as? PostgreSQLDriver {
        let version = try db.raw("SELECT version()")
        return try JSON(node: ["version": version])
    } else {
        return "No db connection"
    }
}

drop.get("admin") { request in
    if let db = drop.database?.driver as? PostgreSQLDriver {
        let tables = try db.raw("SELECT table_name FROM information_schema.tables WHERE table_schema='public' AND table_type='BASE TABLE';")
        let params = try Node(node: ["tables": tables])
        return try drop.view.make("tables", params)
    } else {
        return "No db connection"
    }
}

drop.get("rows") { request in
    guard let tablename = request.data["tablename"]?.string else { return "No tablename sent" }
    
    if let db = drop.database?.driver as? PostgreSQLDriver {
        let objects = try db.raw("SELECT * FROM \(tablename);")
        let acronyms = try objects.makeNode()
        let params = try Node(node: ["acronyms": acronyms])
        return try drop.view.make("index", params)
    } else {
        return "No db connection"
    }
}

drop.get("model") { request in
    let acronym = Acronym(short: "AFK", long: "Away from keyboard")
    return try acronym.makeJSON()
}

drop.get("test") { request in
    var acronym = Acronym(short: "WTF", long: "What the fish")
    try acronym.save()
    return try JSON(node: Acronym.all().makeNode())
}

drop.post("new") { request in
    var acronym = try Acronym(node: request.json)
    try acronym.save()
    return acronym
}

drop.get("all") { request in
    return try Acronym.all().makeJSON()
}

drop.get("first") { request in
    return try JSON(node: Acronym.query().first()?.makeNode())
}

drop.get("afks") { request in
    return try JSON(node: Acronym.query().filter("short", "AFK").all().makeNode())
}

drop.get("not-afks") { request in
    return try JSON(node: Acronym.query().filter("short", .notEquals, "AFK").all().makeNode())
}

drop.get("update") { request in
    guard var first = try Acronym.query().first(),
        let long = request.data["long"]?.string else {
            throw Abort.badRequest
    }
    first.long = long
    try first.save()
    return first
}

drop.get("delete-afks") { request in
    let query = try Acronym.query().filter("short","AFK")
    try query.delete()
    return try Acronym.all().makeJSON()
}

//drop.get("template1") { request in
//    return try drop.view.make("hello", Node(node: ["name":"Ray"]))
//}
//
//drop.get("template2", String.self) { request, name in
//    return try drop.view.make("hello", Node(node: ["name":name]))
//}
//drop.get("template3") { request in
//    let users = try ["RRay","Vicky", "Bryan"].makeNode()
//    return try drop.view.make("hello2", Node(node: ["users": users]))
//}
drop.run()
