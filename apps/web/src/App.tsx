// import logo from './logo.svg'
import {Button} from "@repo/ui/components/button"

function App() {
  return (
    // <div className="text-center">
    //   <header className="min-h-screen flex flex-col items-center justify-center bg-[#282c34] text-white text-[calc(10px+2vmin)]">
    //     <img
    //       src={logo}
    //       className="h-[40vmin] pointer-events-none animate-[spin_20s_linear_infinite]"
    //       alt="logo"
    //     />
    //     <p>
    //       Edit <code>src/App.tsx</code> and save to reload.
    //     </p>
    //     <a
    //       className="text-[#61dafb] hover:underline"
    //       href="https://reactjs.org"
    //       target="_blank"
    //       rel="noopener noreferrer"
    //     >
    //       Learn React
    //     </a>
    //     <a
    //       className="text-[#61dafb] hover:underline"
    //       href="https://tanstack.com"
    //       target="_blank"
    //       rel="noopener noreferrer"
    //     >
    //       Learn TanStack
    //     </a>
    //   </header>
    // </div>
      <div className="bg-amber-700">
          <div>hello</div>
          <Button variant={"secondary"}>A button</Button>
      </div>
  )
}

export default App
