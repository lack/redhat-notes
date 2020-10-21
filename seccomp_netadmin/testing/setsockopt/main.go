package main

import (
	"fmt"
	"net"
	"os"
	"syscall"
)

func setprio(f *os.File, prio int) {
	fmt.Printf("Trying to set priority to %d\n", prio)
	err := syscall.SetsockoptInt(int(f.Fd()), syscall.SOL_SOCKET, syscall.SO_PRIORITY, prio)
	if err != nil {
		fmt.Printf("Setting priority to %d returned error: %v\n", prio, err)
	} else {
		fmt.Printf("Successfully set priority to %d\n", prio)
	}
}

func setdebug(f *os.File) {
	fmt.Printf("Trying to set debug mode\n")
	err := syscall.SetsockoptInt(int(f.Fd()), syscall.SOL_SOCKET, syscall.SO_DEBUG, 1)
	if err != nil {
		fmt.Printf("Setting debug mode returned error: %v\n", err)
	} else {
		fmt.Printf("Successfully set debug mode\n")
	}
}

func setbufforce(f *os.File, rcv bool) {
	name := "SND"
	opt := syscall.SO_SNDBUFFORCE
	if rcv {
		name = "RCV"
		opt = syscall.SO_RCVBUFFORCE
	}
	fmt.Printf("Trying to force %v buffer\n", name)
	err := syscall.SetsockoptInt(int(f.Fd()), syscall.SOL_SOCKET, opt, 1024)
	if err != nil {
		fmt.Printf("Forcing %v buffer returned error: %v\n", name, err)
	} else {
		fmt.Printf("Successfully forced %v buffer\n", name)
	}
}

func main() {
	fmt.Println("Starting the test")
	n, err := net.Dial("udp", "127.0.0.1:6000")
	if err != nil {
		fmt.Println("error opening UDP socket:", err)
		os.Exit(1)
	}
	u, ok := n.(*net.UDPConn)
	if !ok {
		fmt.Println("Error getting UDPConn")
		os.Exit(1)
	}
	f, err := u.File()
	if err != nil {
		fmt.Println("Error getting file from UDP connection:", err)
		os.Exit(1)
	}
	setprio(f, 2)
	setprio(f, 7)
	setprio(f, -1)
	setdebug(f)
	setbufforce(f, true)
	setbufforce(f, false)
}
