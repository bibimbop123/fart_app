import Fluent
import Vapor

func routes(_ app: Application) throws {

app.get { req -> EventLoopFuture<Response> in
    let fileio = req.application.fileio
    let path = req.application.directory.publicDirectory + "audio.mp3"
    return fileio.openFile(path: path, eventLoop: req.eventLoop)
        .flatMap { (handle, region) -> EventLoopFuture<ByteBuffer> in
            let allocator = ByteBufferAllocator()
            return fileio.read(fileRegion: region, allocator: allocator, eventLoop: req.eventLoop)
        }
        .map { buffer -> Response in
            var headers = HTTPHeaders()
            headers.add(name: .contentType, value: "audio/mpeg")
            headers.add(name: .contentLength, value: buffer.readableBytes.description)
            return Response(status: .ok, headers: headers, body: .init(buffer: buffer))
        }
}
}
