from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import asyncio
import os
from semantic_kernel.connectors.ai.open_ai import (
    AzureChatCompletion,
)
from semantic_kernel.connectors.ai.prompt_execution_settings import (
    PromptExecutionSettings,
)
from semantic_kernel.contents import ChatMessageContent, FunctionCallContent, FunctionResultContent
from semantic_kernel.connectors.ai import FunctionChoiceBehavior
from semantic_kernel.functions.kernel_arguments import KernelArguments
from semantic_kernel.kernel import Kernel
from semantic_kernel.connectors.ai.azure_ai_inference import (
    AzureAIInferenceChatPromptExecutionSettings,
    AzureAIInferenceChatCompletion,
)
from semantic_kernel.agents import ChatCompletionAgent, ChatHistoryAgentThread
from azure.ai.inference.aio import ChatCompletionsClient

# ==== Own imports ====
from plugins import WeatherPlugin, LocationPlugin
# from insights_logging import set_up_logging, set_up_tracing, set_up_metrics
from insights_logging import set_up_logging, set_up_tracing, set_up_metrics
from dotenv import load_dotenv

load_dotenv(override=True)

# ==== Set up tracing and logging ====
set_up_logging()
set_up_tracing()
set_up_metrics()


# ==== Credentials ===================
credential = DefaultAzureCredential()
token_provider = get_bearer_token_provider(
    credential, "https://cognitiveservices.azure.com/.default"
)

# ==== Azure OpenAI Service ==========
endpoint = os.environ.get("AOAI_API_BASE")
api_version = os.environ.get("AOAI_API_VERSION")
deployment = os.environ.get("AOAI_LLM_DEPLOYMENT")
temperature = 0


# ==== Stream processing ============
async def stream_processor(response):
    async for message in response:
        if str(message[0]):
            await asyncio.sleep(0.1)
            yield str(message[0])


async def handle_streaming_intermediate_steps(message: ChatMessageContent) -> None:
    for item in message.items or []:
        if isinstance(item, FunctionResultContent):
            print(f"Function Result:> {item.result} for function: {item.name}")
        elif isinstance(item, FunctionCallContent):
            print(f"Function Call:> {item.name} with arguments: {item.arguments}")
        else:
            print(f"{item}")

# === Kernel Settings ==============
kernel = Kernel()

service_id = "sk-agent"

# ai_service = AzureAIInferenceChatCompletion(
#     service_id=service_id,
#     ai_model_id=deployment,
#     client=ChatCompletionsClient(
#         endpoint=f"{str(endpoint)}/openai/deployments/{deployment}",
#         credential=DefaultAzureCredential(),
#         credential_scopes=["https://cognitiveservices.azure.com/.default"],
#         api_version=api_version,
#     ),
# )

ai_service = AzureChatCompletion(
    service_id=service_id,
    endpoint=endpoint,
    deployment_name=deployment,
    credential=DefaultAzureCredential(),
    api_version=api_version
)

kernel.add_service(ai_service)

kernel.add_plugin(WeatherPlugin(), "WeatherPlugin")
kernel.add_plugin(LocationPlugin(), "LocationPlugin")

settings: PromptExecutionSettings = (
    kernel.get_prompt_execution_settings_from_service_id(service_id=service_id)
)
settings.function_choice_behavior = FunctionChoiceBehavior.Auto()

settings.seed = 42
settings.max_tokens = 16000
settings.temperature = 0

# === Create Agent ==================
instructions = """
You are a helpful assistant that helps the user get the weather forecast.
"""

agent = ChatCompletionAgent(
    kernel=kernel,
    name="WeatherAssistant",
    instructions=instructions,
    arguments=KernelArguments(settings=settings),
)


# === Chat function ==============
async def chat() -> bool:
    thread: ChatHistoryAgentThread = None

    try:
        user_input = input("User:> ")

    except KeyboardInterrupt:
        print("\n\nExiting chat...")
        return False
    except EOFError:
        print("\n\nExiting chat...")
        await thread.delete() if thread else None
        return False

    if user_input == "exit":
        print("\n\nExiting chat...")
        await thread.delete() if thread else None
        return False

    print("Assistant:> ", end="", flush=True)
    first_chunk = True

    async for response in agent.invoke_stream(
                messages=user_input,
                thread=thread,
                on_intermediate_message=handle_streaming_intermediate_steps,
            ):
        thread = response.thread
        if first_chunk:
            print(f"# {response.name}: ", end="", flush=True)
            first_chunk = False
        print(response.content, end="", flush=True)
    print()

    return True


async def main() -> None:
    chatting = True
    print(
        "Welcome to your weather assistant.\
        \n  Type 'exit' to exit.\
        \n  Please enter the following information to get the weather: the location."
    )
    while chatting:
        chatting = await chat()

    

if __name__ == "__main__":
    asyncio.run(main())


