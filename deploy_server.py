"""
生产环境HTTP服务器
用于云服务器部署
"""
import http.server
import socketserver
import os
import sys

# 配置
PORT = 8080
HOST = '0.0.0.0'  # 监听所有网络接口

class CustomHandler(http.server.SimpleHTTPRequestHandler):
    """自定义处理器，添加CORS支持"""
    
    def end_headers(self):
        # 添加CORS头
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Cache-Control', 'no-store, no-cache, must-revalidate')
        super().end_headers()
    
    def log_message(self, format, *args):
        """自定义日志格式"""
        sys.stdout.write("%s - [%s] %s\n" %
                         (self.address_string(),
                          self.log_date_time_string(),
                          format % args))

def main():
    # 切换到脚本所在目录
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # 创建服务器
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.TCPServer((HOST, PORT), CustomHandler) as httpd:
        print("=" * 70)
        print("🌐 审批进度可视化服务器")
        print("=" * 70)
        print()
        print(f"✅ 服务器已启动")
        print(f"📍 监听地址: {HOST}:{PORT}")
        print()
        print("💡 访问方式:")
        print(f"   本机: http://localhost:{PORT}")
        print(f"   局域网: http://[服务器IP]:{PORT}")
        print()
        print("⏹  按 Ctrl+C 停止服务器")
        print("=" * 70)
        print()
        
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print()
            print("=" * 70)
            print("👋 服务器已停止")
            print("=" * 70)

if __name__ == '__main__':
    main()
