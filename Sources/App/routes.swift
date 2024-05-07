import Fluent
import Vapor

func routes(_ app: Application) throws {
    app.get { req -> Response in
        let html = """
        <html>
            <head>
                <style>
                    body {
                        display: flex;
                        justify-content: center;
                        align-items: center;
                        height: 100vh;
                        margin: 0;
                        background-color: #f0f0f0;
                        font-family: Arial, sans-serif;
                    }
                    .container {
                        text-align: center;
                    }
                </style>
            </head>
            <body>
                <div class="container">
                    <h1>Welcome to the Fart App!</h1>
                    <p>Click the link below to listen to a fart sound.</p>
                    <a href="/audio">Listen to audio</a>
                    <br/>
                    <img src="/gasleak.jpg" alt="Farting unicorn">
                </div>
            </body>
        </html>
        """
        
        var headers = HTTPHeaders()
        headers.add(name: .contentType, value: "text/html")
        return Response(status: .ok, headers: headers, body: .init(string: html))
    }

    app.get("audio") { req -> EventLoopFuture<Response> in
        let fileio = req.application.fileio
        let fileParam = "audio.mp3"
        
        // Use a relative path
        let path = req.application.directory.publicDirectory + fileParam

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