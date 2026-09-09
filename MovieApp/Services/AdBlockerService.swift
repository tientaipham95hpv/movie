import Foundation
import WebKit

public class AdBlockerService {
    public static let shared = AdBlockerService()
    
    /// Returns custom JavaScript injected into WKWebView to block popups, ads, and redirects
    public var adBlockUserScript: WKUserScript {
        let script = """
        (function() {
            // Block window.open and popup redirects
            window.open = function() { return null; };
            
            // Block ad network domains & tracking scripts
            var adSelectors = [
                'iframe[src*="ads"]',
                'iframe[src*="pop"]',
                'div[id*="ad"]',
                'div[class*="ad-"]',
                'div[class*="banner"]',
                '.popunder',
                '.popup-overlay',
                '#overlay'
            ];
            
            function cleanAds() {
                adSelectors.forEach(function(selector) {
                    var els = document.querySelectorAll(selector);
                    els.forEach(function(el) {
                        el.style.display = 'none';
                        el.remove();
                    });
                });
            }
            
            // Clean on DOMContentLoaded and periodically
            document.addEventListener('DOMContentLoaded', cleanAds);
            setInterval(cleanAds, 1000);
            
            // Prevent dynamic location redirection outside current hostname
            var currentHost = window.location.hostname;
            window.onbeforeunload = function(e) {
                if (window.location.hostname !== currentHost) {
                    e.preventDefault();
                    return false;
                }
            };
        })();
        """
        return WKUserScript(source: script, injectionTime: .atDocumentStart, forMainFrameOnly: false)
    }
}
