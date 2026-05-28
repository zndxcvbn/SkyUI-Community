class skyui.util.SuspendManager
{
  /* PRIVATE VARIABLES */

    private var _target: Object;
    private var _suspended: Boolean = false;
    
    private var _actions: Array;
    private var _actionMap: Object;

    private var _pending: Object;
    private var _intervals: Object;


  /* INITIALIZATION */

    public function SuspendManager(a_target: Object)
    {
        this._target = a_target;
        this._actions = [];
        this._actionMap = {};
        this._pending = {};
        this._intervals = {};
    }


  /* PROPERTIES */

    public function get suspended()
    {
        return this._suspended;
    }

    public function set suspended(a_val: Boolean)
    {
        if (this._suspended == a_val)
            return;

        this._suspended = a_val;

        if (!this._suspended) {
            this.dispatchPending();
        }
    }


  /* PUBLIC FUNCTIONS */

    public function registerAction(a_name: String, a_handler: Object, a_priority: Number, a_supersedes: Array, a_alwaysBatched: Boolean)
    {
        var action = {
            name: a_name,
            methodName: (typeof a_handler == "string") ? String(a_handler) : null,
            callback: (typeof a_handler == "function") ? Function(a_handler) : null,
            priority: a_priority || 0,
            supersedes: a_supersedes || [],
            alwaysBatched: a_alwaysBatched || false
        };
        
        this._actions.push(action);
        this._actionMap[a_name] = action;
        
        this._actions.sortOn("priority", Array.NUMERIC | Array.DESCENDING);
    }

    public function request(a_name: String)
    {
        var action = this._actionMap[a_name];
        if (action == undefined) return;
        
        var len = this._actions.length;
        for (var i = 0; i < len; i++) {
            var pendingAction = this._actions[i];
            
            if (pendingAction == action)
                break;
            
            if (this._pending[pendingAction.name]) {
                var supersedes = pendingAction.supersedes;
                var supLen = supersedes.length;
                for (var j = 0; j < supLen; j++)
                    if (supersedes[j] == a_name)
                        return;
            }
        }

        this._pending[a_name] = true;
        
        var sup = action.supersedes;
        var supLen = sup.length;
        for (var i = 0; i < supLen; i++) {
            this.cancelRequest(sup[i]);
        }

        if (this._suspended) {
            this.clearTimer(a_name);
            return;
        }

        if (action.alwaysBatched) {
            if (this._intervals[a_name] == undefined) {
                this._intervals[a_name] = setInterval(this, "commitAction", 1, a_name);
            }
        } else {
            this.commitAction(a_name);
        }
    }

    public function commitAction(a_name: String)
    {
        this.clearTimer(a_name);
        
        if (this._suspended) {
            this._pending[a_name] = true;
            return;
        }

        if (this._pending[a_name]) {
            this._pending[a_name] = false;
            
            var action = this._actionMap[a_name];
            if (action != undefined) {
                this.executeAction(action);
            }
        }
    }

    public function cancelRequest(a_name: String)
    {
        this._pending[a_name] = false;
        this.clearTimer(a_name);
    }


  /* PRIVATE FUNCTIONS */

    private function clearTimer(a_name: String)
    {
        if (this._intervals[a_name] != undefined) {
            clearInterval(this._intervals[a_name]);
            delete this._intervals[a_name];
        }
    }

    private function executeAction(a_action: Object)
    {
        if (a_action.callback != undefined) {
            a_action.callback();
        } else if (this._target != undefined && a_action.methodName != null) {
            this._target[a_action.methodName]();
        }
    }

    private function dispatchPending()
    {
        var len = this._actions.length;
        for (var i = 0; i < len; i++) {
            if (this._suspended) {
                break;
            }

            var action = this._actions[i];
            var name = action.name;
            
            if (this._pending[name]) {
                this._pending[name] = false;
                this.clearTimer(name);

                var sup = action.supersedes;
                var supLen = sup.length;
                for (var j = 0; j < supLen; j++) {
                    this.cancelRequest(sup[j]);
                }

                this.executeAction(action);
            }
        }
    }
}
