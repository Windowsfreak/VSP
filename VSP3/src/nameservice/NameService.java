package nameservice;

import java.util.HashMap;
import java.util.Map;

public class NameService {
                
        private Map<String, Object> references = new HashMap<String, Object>();
        
        public void rebind(Object servant, String name) {
                this.references.put(name, servant);
        }
        
        public Object resolve(String name) {
                return this.references.get(name);
        }

}