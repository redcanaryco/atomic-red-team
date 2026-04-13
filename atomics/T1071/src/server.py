import argparse
import socket

def main(host, port):
    # Create a socket object
    server_socket = socket.socket(socket.AF_INET, socket.SOCK_STREAM)

    # Bind the socket to the host and port
    server_socket.bind((host, port))

    # Listen for incoming connections
    server_socket.listen(1)

    print('Server listening on {}:{}'.format(host, port))

    while True:
        try:
            # Accept incoming connections
            client_socket, client_address = server_socket.accept()
            print('Connection established with {}:{}'.format(client_address[0], client_address[1]))

            # Send Telnet negotiation
            client_socket.sendall(b"\xFF\xFB\x01")  # Telnet WILL option 01 (echo)
            client_socket.sendall(b"\xFF\xFD\x03")  # Telnet DO option 03 (suppress go ahead)

            # Send a blank string immediately after the client connects
            client_socket.sendall(b"")

            command = ""
            client_socket.sendall(command.encode())

            # Receive output from the client
            output = client_socket.recv(65536)
                
            # Print output (decode if it's command data)
            try:
                print("Output from client:", output.decode())
            except UnicodeDecodeError:
                print("Output from client:", output)

            command = ""
            client_socket.sendall(command.encode())

            # Receive output from the client
            output = client_socket.recv(65536)
                
            # Print output (decode if it's command data)
            try:
                print("Output from client:", output.decode())
            except UnicodeDecodeError:
                print("Output from client:", output)

            while True:
                while True:
                    command = input("Enter command to execute on client: ")
                    if command.strip():
                        break
                    else:
                        print("Command cannot be empty. Please try again.")

                # Send command to the client
                client_socket.sendall(command.encode())

                # Check for exit command
                if command.lower() == "exit":
                    break

                # Receive output from the client
                output = client_socket.recv(65536)

                # Print output (decode if it's command data)
                try:
                    print("Output from client:", output.decode())
                except UnicodeDecodeError:
                    print("Output from client:", output)

            # Close the connection
            client_socket.close()
        except ConnectionAbortedError:
            print("Connection aborted by the client.")
            continue
        except ConnectionResetError:
            print("Connection reset by the client.")
            continue

if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="Telnet server")
    parser.add_argument("host", help="Host IP address")
    parser.add_argument("--port", type=int, default=23, help="Port number (default: 23)")
    args = parser.parse_args()

    main(args.host, args.port)
