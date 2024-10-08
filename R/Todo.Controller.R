Todo.Controller <- \(id, data) {
  moduleServer(
    id,
    \(input, output, session) {
      # Local State
      state <- reactiveValues()
      state[["todos"]] <- data[['retrieve']]()
      state[["todo"]]  <- NULL

      # Input Binding
      observeEvent(input[['create']], { controller[['create']]() })
      observeEvent(input[["todos_rows_selected"]], { controller[["select"]]() }, ignoreNULL = FALSE )
      observeEvent(input[["update"]], { controller[["update"]]() })
      observeEvent(input[["delete"]], { controller[["delete"]]() })

      # Input Verification
      verify <- list()
      verify[["taskEmpty"]]    <- reactive(input[["newTask"]] == '')
      verify[["todoSelected"]] <- reactive(!is.null(input[["todos_rows_selected"]]))

      # User Actions
      controller <- list()
      controller[['create']] <- \() {
        if (!verify[["taskEmpty"]]()) {
          state[["todos"]] <- input[["newTask"]] |> Todo.Model() |> data[['upsert.retrieve']]()
          # Clear the input
          session |> updateTextInput("task", value = '')
        }
      }
      controller[['select']] <- \() {
        if (verify[["todoSelected"]]()) {
          state[["todo"]] <- state[["todos"]][input[["todos_rows_selected"]],]

          session |> updateTextInput("task", value = state[["todo"]][["task"]])
          session |> updateTextInput("status", value = state[["todo"]][["status"]])

        } else {
          state[["todo"]] <- NULL
        }
      }
      controller[['update']] <- \() {
        state[['todo']][["task"]]   <- input[["task"]]
        state[['todo']][["status"]] <- input[["status"]]

        state[["todos"]] <- state[['todo']] |> data[["upsert.retrieve"]]()
      }
      controller[['delete']] <- \() {
        state[["todos"]] <- state[["todo"]][["id"]] |> data[['delete.retrieve']]()
      }

      # Table Configuration
      table.options <- list(
        dom = "t",
        ordering = FALSE,
        columnDefs = list(
          list(visible = FALSE, targets = 0),
          list(width = '50px', targets = 1),
          list(className = 'dt-center', targets = 1),
          list(className = 'dt-left', targets = 2)
        )
      )

      # Output Bindings
      output[["todos"]] <- DT::renderDataTable({
        DT::datatable(
          state[["todos"]],
          selection = 'single',
          rownames = FALSE,
          colnames = c("", ""),
          options = table.options
        )
      })  
      output[["isSelectedTodoVisible"]] <- reactive({ is.data.frame(state[["todo"]]) })
      outputOptions(output, "isSelectedTodoVisible", suspendWhenHidden = FALSE) 
    }
  )
}
