from azure.identity import DefaultAzureCredential, get_bearer_token_provider
import asyncio
import os
from semantic_kernel.connectors.ai.open_ai import (
    AzureChatCompletion,
)
from semantic_kernel.connectors.ai.prompt_execution_settings import (
    PromptExecutionSettings,
)
from semantic_kernel.contents.chat_history import ChatHistory
from semantic_kernel.connectors.ai import FunctionChoiceBehavior
from semantic_kernel.functions.kernel_arguments import KernelArguments
from semantic_kernel.kernel import Kernel
from semantic_kernel.connectors.ai.azure_ai_inference import (
    AzureAIInferenceChatPromptExecutionSettings,
    AzureAIInferenceChatCompletion,
)
from azure.ai.inference.aio import ChatCompletionsClient
import logging
import json

# ==== Own imports ====
from plugins import WeatherPlugin, LocationPlugin
from insights_logging import set_up_logging, set_up_tracing, set_up_metrics


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

# === Kernel Settings ==============
kernel = Kernel()

service_id = "sk-agent"

ai_service = AzureAIInferenceChatCompletion(
    service_id=service_id,
    ai_model_id=deployment,
    client=ChatCompletionsClient(
        endpoint=f"{str(endpoint)}/openai/deployments/{deployment}",
        credential=DefaultAzureCredential(),
        credential_scopes=["https://cognitiveservices.azure.com/.default"],
        api_version=api_version,
    ),
)

kernel.add_service(ai_service)

kernel.add_plugin(WeatherPlugin(), "WeatherPlugin")
kernel.add_plugin(LocationPlugin(), "LocationPlugin")

chat_function = kernel.add_function(
    plugin_name="ChatBot",
    function_name="Chat",
    prompt="You provide information about temperature. {{$chat_history}}{{$user_input}}",
    template_format="semantic-kernel",
)

settings: PromptExecutionSettings = (
    kernel.get_prompt_execution_settings_from_service_id(service_id=service_id)
)
settings.function_choice_behavior = FunctionChoiceBehavior.Auto(
    filters={"excluded_plugins": ["ChatBot"]}
)

settings.seed = 42
settings.max_tokens = 16000
settings.temperature = 0

chat_history = ChatHistory()

# === Chat function ==============
async def chat() -> bool:
    try:
        user_input = input("User:> ")
    except KeyboardInterrupt:
        print("\n\nExiting chat...")
        return False
    except EOFError:
        print("\n\nExiting chat...")
        return False

    if user_input == "exit":
        print("\n\nExiting chat...")
        return False

    print("Assistant:> ", end="", flush=True)
    async for update in kernel.invoke_stream(
        function=chat_function,
        arguments=KernelArguments(user_input=user_input, chat_history=chat_history, settings=settings)
    ):
        print(f"{update[0].content}", end="", flush=True)
     
    print()

    chat_history.add_user_message(user_input)
    chat_history.add_assistant_message(update[0].content if update else "")

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


