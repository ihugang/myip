//
//  AppDelegate.swift
//  myip
//
//  Created by Hu Gang on 2024/7/7.
//

import Cocoa
import ServiceManagement

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {

   var statusItem: NSStatusItem!
   var showExternalIP = true
   var timer: Timer?
   var wanIP: String?
   var lanIP: String?

   func applicationDidFinishLaunching(_ aNotification: Notification) {
         // 设置应用程序为无界面应用
      NSApp.setActivationPolicy(.accessory)

         // 创建状态栏项目
      statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

      if let button = statusItem.button {
         button.target = self
         button.action = #selector(statusItemClicked)
         button.sendAction(on: [.leftMouseUp, .rightMouseUp])
      }

         // 设置右键菜单
      setupMenu()

         // 设置定时器每 3 秒检查 IP 并切换显示
      timer = Timer.scheduledTimer(timeInterval: 3.0, target: self, selector: #selector(checkAndUpdateIP), userInfo: nil, repeats: true)

         // 初始化 IP 信息
      updateIPAddress()
   }

   @objc func statusItemClicked() {
      if let event = NSApp.currentEvent {
         if event.type == .rightMouseUp {
            statusItem.menu?.popUp(positioning: nil, at: NSEvent.mouseLocation, in: nil)
         }
      }
   }

   @objc func toggleIPAddress() {
      showExternalIP.toggle()
      updateStatusItem()
   }

   @objc func checkAndUpdateIP() {
      DispatchQueue.global(qos: .background).async {
         let newWanIP = self.getExternalIPAddress()
         let newLanIP = self.getLocalIPAddress()

         if newWanIP != self.wanIP || newLanIP != self.lanIP {
            self.wanIP = newWanIP
            self.lanIP = newLanIP
            DispatchQueue.main.async {
               self.updateStatusItem()
               self.updateMenu()
            }
         } else {
            DispatchQueue.main.async {
               self.toggleIPAddress()
            }
         }
      }
   }

   func updateStatusItem() {
      if showExternalIP {
         statusItem.button?.image = NSImage(systemSymbolName: "network", accessibilityDescription: "WAN")
         statusItem.button?.title = " \(wanIP ?? "WAN Not Found")"
      } else {
         let localIPType = getLocalIPType()
         if localIPType == "Wi-Fi" {
            statusItem.button?.image = NSImage(systemSymbolName: "wifi", accessibilityDescription: "LAN")
         } else {
            statusItem.button?.image = NSImage(systemSymbolName: "link", accessibilityDescription: "LAN")
         }
         statusItem.button?.title = " \(lanIP ?? "LAN Not Found")"
      }
   }

   func updateIPAddress() {
      DispatchQueue.global(qos: .background).async {
         self.wanIP = self.getExternalIPAddress()
         self.lanIP = self.getLocalIPAddress()
         DispatchQueue.main.async {
            self.updateStatusItem()
            self.updateMenu()
         }
      }
   }

   func getExternalIPAddress() -> String? {
      let url = URL(string: "https://api.ipify.org")!
      let semaphore = DispatchSemaphore(value: 0)
      var externalIP: String?

      let task = URLSession.shared.dataTask(with: url) { data, response, error in
         defer { semaphore.signal() }
         if let error = error {
            print("Error fetching external IP address: \(error.localizedDescription)")
            return
         }
         guard let data = data, let ip = String(data: data, encoding: .utf8) else {
            print("Invalid data or unable to decode data")
            return
         }
         externalIP = ip
      }

      task.resume()
      semaphore.wait()
      return externalIP
   }

   func getLocalIPAddress() -> String? {
      var address: String?
      var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

      if getifaddrs(&ifaddr) == 0 {
         var ptr = ifaddr
         while ptr != nil {
            let flags = Int32(ptr!.pointee.ifa_flags)
            var addr = ptr!.pointee.ifa_addr.pointee

            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
               if addr.sa_family == UInt8(AF_INET) {
                  if let name = ptr?.pointee.ifa_name {
                     let interface = String(cString: name)
                     if interface == "en0" || interface == "en1" {
                        var hostname = [CChar](repeating: 0, count: Int(NI_MAXHOST))
                        if getnameinfo(&addr, socklen_t(addr.sa_len), &hostname, socklen_t(hostname.count), nil, socklen_t(0), NI_NUMERICHOST) == 0 {
                           address = String(cString: hostname)
                        }
                     }
                  }
               }
            }
            ptr = ptr?.pointee.ifa_next
         }
         freeifaddrs(ifaddr)
      }
      return address
   }

   func getLocalIPType() -> String {
      var ipType = "Ethernet"
      var ifaddr: UnsafeMutablePointer<ifaddrs>? = nil

      if getifaddrs(&ifaddr) == 0 {
         var ptr = ifaddr
         while ptr != nil {
            let flags = Int32(ptr!.pointee.ifa_flags)
            var addr = ptr!.pointee.ifa_addr.pointee

            if (flags & (IFF_UP|IFF_RUNNING|IFF_LOOPBACK)) == (IFF_UP|IFF_RUNNING) {
               if addr.sa_family == UInt8(AF_INET) {
                  if let name = ptr?.pointee.ifa_name {
                     let interface = String(cString: name)
                     if interface == "en0" {
                        ipType = "Wi-Fi"
                     } else if interface == "en1" {
                        ipType = "Ethernet"
                     }
                  }
               }
            }
            ptr = ptr?.pointee.ifa_next
         }
         freeifaddrs(ifaddr)
      }
      return ipType
   }

   func setupMenu() {
      let menu = NSMenu()
      statusItem.menu = menu
      updateMenu()
   }

   func updateMenu() {
      guard let menu = statusItem.menu else { return }
      menu.removeAllItems()

         // 添加 WAN 信息
      let wanItem = NSMenuItem(title: "WAN IP: \(wanIP ?? "Not Found")", action: #selector(copyWanIP), keyEquivalent: "")
      wanItem.target = self
      menu.addItem(wanItem)

         // 添加 LAN 信息
      let lanItem = NSMenuItem(title: "LAN IP: \(lanIP ?? "Not Found")", action: #selector(copyLanIP), keyEquivalent: "")
      lanItem.target = self
      menu.addItem(lanItem)

      menu.addItem(NSMenuItem.separator())

         // 添加启动项菜单
      let launchItem = NSMenuItem(title: "Launch at Startup", action: #selector(toggleLaunchAtStartup(_:)), keyEquivalent: "")
      launchItem.state = isAppLoginItem() ? .on : .off
      menu.addItem(launchItem)

         // 添加关闭菜单
      let quitItem = NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q")
      menu.addItem(quitItem)
   }

   @objc func copyWanIP() {
      if let wanIP = wanIP {
         NSPasteboard.general.clearContents()
         NSPasteboard.general.setString(wanIP, forType: .string)
      }
   }

   @objc func copyLanIP() {
      if let lanIP = lanIP {
         NSPasteboard.general.clearContents()
         NSPasteboard.general.setString(lanIP, forType: .string)
      }
   }

   @objc func toggleLaunchAtStartup(_ sender: NSMenuItem) {
      let currentlyEnabled = isAppLoginItem()

      if currentlyEnabled {
         do {
            try SMAppService.mainApp.unregister()
         } catch {
            print("Error unregistering app as login item: \(error)")
         }
      } else {
         do {
            try SMAppService.mainApp.register()
         } catch {
            print("Error registering app as login item: \(error)")
         }
      }

      sender.state = currentlyEnabled ? .off : .on
   }

   func isAppLoginItem() -> Bool {
      return SMAppService.mainApp.status == .enabled
   }

   @objc func quitApp() {
      NSApplication.shared.terminate(self)
   }
}
