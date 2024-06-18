const scriptElement = document.currentScript;
const scriptSrc = scriptElement.getAttribute('src');
console.log(`➡ JavaScript loaded from ${scriptSrc}`);

// async
async function configureBitcoinPriceChecker() {
   const bitcoinGetPriceButton = document.querySelector('.bitcoinGetPriceButton'); // TODO: there should be exactly one
   console.log(`🔥 configureBitcoinPriceChecker found button text ${bitcoinGetPriceButton.textContent}`);
   const bitcoinPriceContainer = document.querySelector('.bitcoinPriceContainer'); // TODO: there should be exactly one
   console.log(`🔥 configureBitcoinPriceChecker found container ${bitcoinPriceContainer}`);
   
   bitcoinGetPriceButton.addEventListener('click', async () => {
      try {
         let message = await handleBitcoinPriceCheck(bitcoinGetPriceButton, bitcoinPriceContainer);
         console.log(`🔥 handleBitcoinPriceCheck resolved with ${message}`);
      } catch (error) {
         console.error('Error:', error);
      }
   });
}

// document.querySelector('button').addEventListener('click', async () => {
//    const resultContainer = document.getElementById('BitcoinPriceCheckResults');
//    try {
//       let message = await handleBitcoinPriceCheck(resultContainer);
//       console.log(`🔥 handleBitcoinPriceCheck resolved with ${message}`);
//    } catch (error) {
//       console.error('Error:', error);
//    }
// });

async function handleBitcoinPriceCheck(startRequestButton, resultElement) {
   console.log(`🔥 handleBitcoinPriceCheck started from button {startRequestButton}`); // later add disabling

   const api = 'https://api.coindesk.com/v1/bpi/currentprice/USD.json';
   const web = 'https://www.coindesk.com/indices/xbx';
   try {
      const response = await fetch(api);
      const json = await response.json();
      const message = `Bitcoin Price as of ${json.time.updated}:\n\n${json.bpi.USD.rate} ${json.bpi.USD.code}\n\n${json.disclaimer}.\n\nSee also ${web}.`;
      // resultElement.textContent = message; // doesn't always work, and is not the best practice anyway - use value property
      resultElement.value = message;
      console.log(json);
      console.log(message);
      return message;
   } catch (error) {
      console.error('Error fetching current Bitcoin price:', error);
      resultElement.textContent = 'Error fetching current Bitcoin price.';
      throw error;
   }
}

// Let's get configured! 
configureBitcoinPriceChecker();
