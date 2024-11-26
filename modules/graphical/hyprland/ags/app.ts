import { App } from "astal/gtk4"
import Bar from "./Bar"
import style from "./style.scss"

App.start({
  css: style,
  instanceName: "js",
  main: () => App.get_monitors().map(Bar),
  requestHandler: (request, response) => {
    print(request)
    response("ok")
  },
})
