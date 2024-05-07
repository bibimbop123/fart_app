import Fluent
import Vapor

func routes(_ app: Application) throws {

    app.get { req in
        return "Hello, world!"
    }
app.get("audio") { req -> EventLoopFuture<Response> in
    let fileio = req.application.fileio
    let fileParam = "audio.mp3"
    let path = "/Users/brian/Projects/FartApp/Public/\(fileParam)"
    
    let fileExists = req.eventLoop.submit {
        FileManager.default.fileExists(atPath: path)
    }
    
    return fileExists.flatMap { exists in
        guard exists else {
            return req.eventLoop.makeFailedFuture(Abort(.notFound))
        }
        
        return fileio.openFile(path: path, eventLoop: req.eventLoop)
            .flatMapError { error in
                return req.eventLoop.makeFailedFuture(Abort(.internalServerError, reason: "Failed to open file: \(error)"))
            }
            .flatMap { (handle, region) -> EventLoopFuture<ByteBuffer> in
                let allocator = ByteBufferAllocator()
                let readFuture = fileio.read(fileRegion: region, allocator: allocator, eventLoop: req.eventLoop)
                readFuture.whenComplete { _ in
                    // Close the file handle when we're done with it
                    try? handle.close()
                }
                return readFuture
            }
            .map { buffer -> Response in
                var headers = HTTPHeaders()
                headers.add(name: .contentType, value: "audio/mpeg")
                headers.add(name: .contentLength, value: buffer.readableBytes.description)
                return Response(status: .ok, headers: headers, body: .init(buffer: buffer))
            }
    }
}
}